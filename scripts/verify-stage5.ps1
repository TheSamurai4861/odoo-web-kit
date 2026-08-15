[CmdletBinding()]
param(
    [switch]$Browser
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\dev-env.ps1")
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$workspace = $dev.Workspace
$runtime = $dev.Runtime
$python = $dev.Python
$psql = $dev.Psql

# All previous functional, responsive and accessibility guarantees are gates.
& (Join-Path $PSScriptRoot "verify-stage4.ps1") -Browser:$Browser

Push-Location $workspace
try {
    node --check "website_webkit\static\src\builder\webkit_hero_option_plugin.js"
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 5 builder plugin contains invalid JavaScript."
    }

    @'
import ast
from pathlib import Path

from lxml import etree

root = Path("website_webkit")
manifest = ast.literal_eval((root / "__manifest__.py").read_text(encoding="utf-8"))
assert manifest["version"] == "19.0.5.0.0"
assert manifest["assets"]["website.website_builder_assets"] == [
    "website_webkit/static/src/builder/**/*",
]
assert not any(
    "builder" in asset
    for asset in manifest["assets"]["web.assets_frontend"]
)

hero = etree.parse(str(root / "views/snippets/s_webkit_hero.xml"))
hero_section = hero.xpath("//template[@id='s_webkit_hero']/section")[0]
classes = set(hero_section.get("class", "").split())
assert {"webkit_hero_align_start", "webkit_hero_media_end", "o_cc1"} <= classes
assert not {"webkit_hero_align_center", "webkit_hero_media_start", "o_cc5"} & classes

option_xml_path = root / "static/src/builder/webkit_hero_option.xml"
option_document = etree.parse(str(option_xml_path))
templates = option_document.xpath(
    "//t[@*[name()='t-name']='website_webkit.WebkitHeroOption']"
)
assert len(templates) == 1
template = templates[0]
rows = template.xpath("./BuilderRow")
assert [row.get("label.translate") for row in rows] == [
    "Content alignment",
    "Visual position",
    "Tone",
]
assert len(template.xpath(".//BuilderButtonGroup")) == 3
class_actions = [
    value.strip("'") for value in template.xpath(".//BuilderButton/@classAction")
]
assert class_actions == [
    "webkit_hero_align_start",
    "webkit_hero_align_center",
    "webkit_hero_media_end",
    "webkit_hero_media_start",
    "o_cc1",
    "o_cc5",
]

plugin = (root / "static/src/builder/webkit_hero_option_plugin.js").read_text(
    encoding="utf-8"
)
for contract in (
    'extends BaseOptionComponent',
    'static selector = ".s_webkit_hero"',
    'withSequence(SNIPPET_SPECIFIC, WebkitHeroOption)',
    'registry.category("website-plugins")',
):
    assert contract in plugin, contract
assert "extends BuilderAction" not in plugin

all_xml = "\n".join(path.read_text(encoding="utf-8") for path in root.rglob("*.xml"))
assert "website.snippet_options" not in all_xml
assert "<we-button" not in all_xml
assert "<we-range" not in all_xml

hero_scss = (root / "static/src/scss/_hero.scss").read_text(encoding="utf-8")
for variant in (
    "webkit_hero_align_center",
    "webkit_hero_media_start",
    "&.o_cc5",
    "media-breakpoint-up(xl)",
):
    assert variant in hero_scss, variant

print("stage5_manifest_version=OK")
print("odoo19_builder_asset_scope=OK")
print("declarative_class_actions=OK")
print("legacy_snippet_option_api=ABSENT")
print("custom_builder_actions=ABSENT")
print("hero_variant_styles=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 5 static validation failed."
    }
} finally {
    Pop-Location
}

$env:PGPASSWORD = [IO.File]::ReadAllText(
    (Join-Path $runtime "secrets\odoo-db-password")
).Trim()
try {
    $moduleState = & $psql `
        -X -v ON_ERROR_STOP=1 `
        -h $dev.PgHost -p $dev.PgPort `
        -U $dev.DbUser -d $dev.Database `
        -At -F "|" `
        -c "select name,state,latest_version from ir_module_module where name='website_webkit';"
    if ($LASTEXITCODE -ne 0 -or $moduleState -ne "website_webkit|installed|19.0.5.0.0") {
        throw "website_webkit 19.0.5.0.0 is not installed."
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

import requests
from lxml import html

base = os.environ.get("WEBKIT_BASE_URL", "http://127.0.0.1:8069").rstrip("/")
database = os.environ.get("WEBKIT_DB", "webkit_dev")
session = requests.Session()
auth = session.post(base + "/web/session/authenticate", json={
    "jsonrpc": "2.0",
    "method": "call",
    "params": {
        "db": database,
        "login": "admin",
        "password": os.environ["WEBKIT_ODOO_ADMIN_PASSWORD"],
    },
    "id": 1,
}, timeout=30).json()
assert auth.get("result", {}).get("uid")

for path in (
    "/website_webkit/static/src/builder/webkit_hero_option_plugin.js",
    "/website_webkit/static/src/builder/webkit_hero_option.xml",
):
    response = session.get(base + path, timeout=30)
    assert response.status_code == 200, (path, response.status_code)

page = session.get(base + "/", timeout=30)
page.raise_for_status()
document = html.fromstring(page.content)
heroes = document.xpath('//section[contains(concat(" ", @class, " "), " s_webkit_hero ")]')
assert len(heroes) == 1
classes = set(heroes[0].get("class", "").split())
assert {"webkit_hero_align_start", "webkit_hero_media_end", "o_cc1"} <= classes
assert not {"webkit_hero_align_center", "webkit_hero_media_start", "o_cc5"} & classes

print("builder_sources_http=OK")
print("canonical_hero_defaults_http=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 5 HTTP validation failed."
    }
} finally {
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue
}

if ($Browser) {
    $playwright = Join-Path $runtime "browser-check\node_modules\playwright-core"
    if (-not (Test-Path -LiteralPath $playwright)) {
        throw "Playwright Core is missing from $playwright."
    }
    node (Join-Path $PSScriptRoot "verify-stage5-browser.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 5 browser acceptance test failed."
    }
}

$log = Join-Path $runtime "odoo.log"
$marker = (Select-String -LiteralPath $log -Pattern "Odoo version 19.0" | Select-Object -Last 1).LineNumber
$currentLog = Get-Content -LiteralPath $log | Select-Object -Skip ($marker - 1)
$issues = $currentLog |
    Select-String -Pattern " ERROR | CRITICAL |Traceback" |
    Where-Object {
        $_.Line -notmatch "odoo\.sql_db: bad query:.*WITH visitor AS"
    }
$visitorRetries = $currentLog |
    Select-String -Pattern "SERIALIZATION_FAILURE, [1-9][0-9]* tries left"
if ($visitorRetries) {
    Write-Output "website_visitor_serialization_retries=$($visitorRetries.Count) (recovered by Odoo)"
}
if ($issues) {
    throw "Errors were found in the current Odoo log."
}

Write-Output "Stage 5 validation completed successfully."
