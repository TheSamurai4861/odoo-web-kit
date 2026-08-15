[CmdletBinding()]
param(
    [switch]$Browser,
    [switch]$Lifecycle,
    [switch]$Lighthouse,
    [switch]$Full
)

$ErrorActionPreference = "Stop"

if ($Full) {
    $Browser = $true
    $Lifecycle = $true
    $Lighthouse = $true
}

. (Join-Path $PSScriptRoot "lib\dev-env.ps1")
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$workspace = $dev.Workspace
$odooSource = $dev.OdooSource
$python = $dev.Python

# This gate starts with the same dependency-free checks used by CI.
Assert-WebKitPath -Path $python -Description "Python executable" -Type Leaf
& $python (Join-Path $PSScriptRoot "verify-portable.py")
if ($LASTEXITCODE -ne 0) {
    throw "Portable source validation failed."
}

# Stages 1-5 remain hard release gates for Stage 6.
& (Join-Path $PSScriptRoot "verify-stage5.ps1") -Browser:$Browser

Push-Location $workspace
try {
    $scriptFiles = @(
        Get-ChildItem -Path "scripts", "website_webkit" -Recurse -File |
            Where-Object { $_.Extension -in ".js", ".cjs" }
    )
    foreach ($scriptFile in $scriptFiles) {
        node --check $scriptFile.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "Invalid JavaScript: $($scriptFile.FullName)"
        }
    }

    @'
import ast
import re
from pathlib import Path

from lxml import etree

root = Path("website_webkit")
manifest = ast.literal_eval((root / "__manifest__.py").read_text(encoding="utf-8"))

assert manifest["name"] == "Odoo Web Kit"
assert manifest["version"] == "19.0.5.0.0"
assert manifest["license"] == "LGPL-3"
assert manifest["depends"] == ["website"]
assert manifest["application"] is False
assert manifest["installable"] is True

for relative_path in manifest["data"]:
    assert (root / relative_path).is_file(), relative_path

builder_files = sorted((root / "static/src/builder").glob("**/*"))
builder_files = [path for path in builder_files if path.is_file()]
assert builder_files
assert manifest["assets"]["website.website_builder_assets"] == [
    "website_webkit/static/src/builder/**/*",
]
frontend_assets = manifest["assets"]["web.assets_frontend"]
assert frontend_assets
assert all(path.endswith(".scss") for path in frontend_assets)
assert not (root / "static/src/js").exists()

package_files = sorted(
    path for path in root.rglob("*")
    if path.is_file() and "__pycache__" not in path.parts
)
allowed_suffixes = {".py", ".xml", ".js", ".scss", ".svg"}
unexpected = [str(path) for path in package_files if path.suffix not in allowed_suffixes]
assert not unexpected, unexpected
assert len(package_files) == 23, len(package_files)

package_bytes = sum(path.stat().st_size for path in package_files)
svg_files = [path for path in package_files if path.suffix == ".svg"]
scss_files = [path for path in package_files if path.suffix == ".scss"]
builder_bytes = sum(path.stat().st_size for path in builder_files)
svg_bytes = sum(path.stat().st_size for path in svg_files)
scss_bytes = sum(path.stat().st_size for path in scss_files)
assert package_bytes <= 65_536, package_bytes
assert svg_bytes <= 16_384, svg_bytes
assert max(path.stat().st_size for path in svg_files) <= 8_192
assert builder_bytes <= 8_192, builder_bytes
assert scss_bytes <= 16_384, scss_bytes

parser = etree.XMLParser(
    resolve_entities=False,
    no_network=True,
    load_dtd=False,
    recover=False,
)
for path in package_files:
    source = path.read_text(encoding="utf-8")
    lowered = source.lower()
    assert "<!doctype" not in lowered, path
    assert "<!entity" not in lowered, path
    assert "<script" not in lowered, path
    assert "javascript:" not in lowered, path
    assert "<foreignobject" not in lowered, path
    assert not re.search(r"(?:href|src)\s*=\s*[\"']https?://", source, re.I), path
    assert not re.search(r"url\(\s*[\"']?https?://", source, re.I), path
    if path.suffix in {".xml", ".svg"}:
        etree.parse(str(path), parser)

gitignore = Path(".gitignore").read_text(encoding="utf-8")
assert "__pycache__/" in gitignore
assert "*.py[cod]" in gitignore

print(f"package_files={len(package_files)}")
print(f"package_bytes={package_bytes}")
print(f"scss_bytes={scss_bytes}")
print(f"svg_bytes={svg_bytes}")
print(f"builder_bytes={builder_bytes}")
print("package_audit=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 6 package audit failed."
    }
} finally {
    Pop-Location
}

$coreBranch = git -C $odooSource branch --show-current
if ($LASTEXITCODE -ne 0 -or $coreBranch -ne "19.0") {
    throw "The Odoo source is not on branch 19.0."
}
$coreChanges = @(git -C $odooSource status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $coreChanges.Count -ne 0) {
    $coreChanges
    throw "The Odoo source tree contains local modifications."
}
$coreCommit = git -C $odooSource rev-parse --short=8 HEAD
if ($LASTEXITCODE -ne 0) {
    throw "Unable to identify the Odoo source commit."
}
Write-Output "odoo_core=clean|branch=$coreBranch|commit=$coreCommit"

if ($Browser) {
    node (Join-Path $PSScriptRoot "verify-stage6-browser.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 6 keyboard and 200% zoom validation failed."
    }
}

if ($Lifecycle) {
    & (Join-Path $PSScriptRoot "verify-stage6-lifecycle.ps1")
}

if ($Lighthouse) {
    & (Join-Path $PSScriptRoot "verify-stage6-lighthouse.ps1")
}

Write-Output "Stage 6 quality validation completed successfully."
