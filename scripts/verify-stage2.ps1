[CmdletBinding()]
param(
    [switch]$Browser
)

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$runtime = Join-Path $odooRoot ".runtime"
$python = Join-Path $odooRoot ".venv-odoo19\Scripts\python.exe"
$odooBin = Join-Path $odooRoot "odoo-19\odoo-bin"
$config = Join-Path $runtime "odoo-dev.conf"
$pgBin = "C:\Program Files\PostgreSQL\16\bin"

& (Join-Path $PSScriptRoot "verify-dev.ps1")

Push-Location $workspace
try {
    @'
import ast
from pathlib import Path
from lxml import etree

root = Path("website_webkit")
manifest = ast.literal_eval((root / "__manifest__.py").read_text(encoding="utf-8"))
assert manifest["version"].startswith("19.0.")
assert manifest["depends"] == ["website"]
assert manifest["application"] is False
for relative in manifest["data"]:
    etree.parse(str(root / relative))
for path in root.rglob("*.svg"):
    etree.parse(str(path))
scss = (root / "static/src/scss/webkit.scss").read_text(encoding="utf-8")
assert scss.lstrip().startswith(".s_webkit_hello")
assert not (root / "static/src/js").exists()
print("module_files=OK")
print("manifest=OK")
print("xml_svg=OK")
print("scss_namespace=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The static module validation failed."
    }
} finally {
    Pop-Location
}

$env:PGPASSWORD = [IO.File]::ReadAllText(
    (Join-Path $runtime "secrets\odoo-db-password")
).Trim()
try {
    $moduleState = & (Join-Path $pgBin "psql.exe") `
        -X -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p 5433 `
        -U odoo_webkit -d webkit_dev `
        -At -F "|" `
        -c "select name,state,latest_version from ir_module_module where name='website_webkit';"
    if ($LASTEXITCODE -ne 0 -or $moduleState -notmatch '^website_webkit\|installed\|19\.0\.') {
        throw "website_webkit is not installed with an Odoo 19 version."
    }
    Write-Output "module_state=$moduleState"
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

$env:WEBKIT_ODOO_ADMIN_PASSWORD = [IO.File]::ReadAllText(
    (Join-Path $runtime "secrets\odoo-admin-password")
).Trim()
try {
    @'
import os
import re
import requests

base = "http://127.0.0.1:8069"
session = requests.Session()
auth = session.post(base + "/web/session/authenticate", json={
    "jsonrpc": "2.0",
    "method": "call",
    "params": {
        "db": "webkit_dev",
        "login": "admin",
        "password": os.environ["WEBKIT_ODOO_ADMIN_PASSWORD"],
    },
    "id": 1,
}, timeout=30).json()
assert auth.get("result", {}).get("uid")

for path in (
    "/website_webkit/static/src/img/wbuilder/webkit_group.svg",
    "/website_webkit/static/src/img/wbuilder/s_webkit_hello.svg",
):
    response = session.get(base + path, timeout=30)
    assert response.status_code == 200, (path, response.status_code)

page = session.get(base + "/?debug=assets", timeout=30)
css_path = re.search(r'href="([^"]*web\.assets_frontend\.css)"', page.text).group(1)
css = session.get(base + css_path, timeout=60)
assert css.status_code == 200
assert "website_webkit/static/src/scss/webkit.scss" in css.text
assert ".s_webkit_hello" in css.text
print("static_assets=OK")
print("frontend_scss_bundle=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The HTTP asset validation failed."
    }
} finally {
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue
}

@'
from lxml import etree

registry = env.ref("website.snippets")
combined = etree.tostring(registry._get_combined_arch(), encoding="unicode")
assert combined.count('snippet-group="webkit"') == 1
assert combined.count('t-snippet="website_webkit.s_webkit_hello"') == 1

snippet = env.ref("website_webkit.s_webkit_hello")
assert snippet.active and snippet.type == "qweb"

homepage = env["ir.ui.view"].search([
    ("key", "=", "website.homepage"),
    ("website_id", "!=", False),
], limit=1)
doc = etree.fromstring(homepage.arch_db.encode())
sections = doc.xpath(
    "//section[contains(concat(' ', normalize-space(@class), ' '), ' s_webkit_hello ')]"
)
assert len(sections) == 1
assert sections[0].get("data-snippet") == "s_webkit_hello"
assert sections[0].get("data-name") == "Hello Web Kit"
assert "Stage 2 verified" in "".join(sections[0].itertext())
print("combined_registry=OK")
print("persisted_homepage_snippet=OK")
'@ | & $python $odooBin shell -c $config -d webkit_dev --no-http
if ($LASTEXITCODE -ne 0) {
    throw "The Odoo registry or persistence validation failed."
}

if ($Browser) {
    $playwright = Join-Path $runtime "browser-check\node_modules\playwright-core"
    if (-not (Test-Path -LiteralPath $playwright)) {
        throw "Playwright Core is missing from $playwright."
    }
    node (Join-Path $PSScriptRoot "verify-stage2-browser.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "The browser acceptance test failed."
    }
}

$log = Join-Path $runtime "odoo.log"
$marker = (Select-String -LiteralPath $log -Pattern "Odoo version 19.0" | Select-Object -Last 1).LineNumber
$issues = (Get-Content -LiteralPath $log | Select-Object -Skip ($marker - 1)) |
    Select-String -Pattern " ERROR | CRITICAL |Traceback"
if ($issues) {
    throw "Errors were found in the current Odoo log."
}

Write-Output "Stage 2 validation completed successfully."
