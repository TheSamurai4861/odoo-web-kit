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
import re
from pathlib import Path

from lxml import etree

root = Path("website_webkit")
snippet_ids = (
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
)
expected_data = [
    f"views/snippets/{snippet_id}.xml" for snippet_id in snippet_ids
] + ["views/snippets/snippets.xml"]
expected_assets = [
    "website_webkit/static/src/scss/_tokens.scss",
    "website_webkit/static/src/scss/_hero.scss",
    "website_webkit/static/src/scss/_features.scss",
    "website_webkit/static/src/scss/_trust.scss",
    "website_webkit/static/src/scss/_cta.scss",
    "website_webkit/static/src/scss/webkit.scss",
]

manifest = ast.literal_eval((root / "__manifest__.py").read_text(encoding="utf-8"))
version = tuple(map(int, manifest["version"].split(".")))
assert version[:2] == (19, 0) and version >= (19, 0, 2, 0, 0)
assert manifest["depends"] == ["website"]
assert manifest["data"] == expected_data
assert manifest["assets"]["web.assets_frontend"] == expected_assets
assert manifest["application"] is False and manifest["installable"] is True

parser = etree.XMLParser(resolve_entities=False, no_network=True)
for relative in manifest["data"]:
    etree.parse(str(root / relative), parser)
for path in root.rglob("*.svg"):
    etree.parse(str(path), parser)

for snippet_id in snippet_ids:
    document = etree.parse(str(root / f"views/snippets/{snippet_id}.xml"), parser)
    templates = document.xpath(f"//template[@id='{snippet_id}']")
    assert len(templates) == 1
    sections = templates[0].xpath("./section")
    assert len(sections) == 1
    section = sections[0]
    assert snippet_id in section.get("class", "").split()
    assert section.get("id") is None
    for image in section.xpath(".//img"):
        assert image.get("src", "").startswith("/website_webkit/static/")
        assert image.get("alt", "").strip()
        assert "img" in image.get("class", "").split()
    for link in section.xpath(".//a"):
        assert link.get("href", "").startswith("/")

registry = etree.parse(str(root / "views/snippets/snippets.xml"), parser)
assert len(registry.xpath("//t[@snippet-group='webkit']")) == 1
registered = registry.xpath("//t[@group='webkit']/@t-snippet")
assert registered == [f"website_webkit.{snippet_id}" for snippet_id in snippet_ids]

assert etree.parse(str(root / "views/snippets/s_webkit_features.xml"), parser).xpath("count(//article)") == 3
assert etree.parse(str(root / "views/snippets/s_webkit_trust.xml"), parser).xpath("count(//blockquote)") == 1
assert etree.parse(str(root / "views/snippets/s_webkit_cta.xml"), parser).xpath("count(//a[@href='/contactus'])") == 1

for snippet_id in snippet_ids:
    scss = (root / f"static/src/scss/_{snippet_id.removeprefix('s_webkit_')}.scss").read_text(encoding="utf-8")
    assert re.match(rf"\s*\.{snippet_id}\s*\{{", scss)
entrypoint = (root / "static/src/scss/webkit.scss").read_text(encoding="utf-8")
assert "@import" not in entrypoint
assert not (root / "static/src/js").exists()

print("manifest_and_asset_order=OK")
print("xml_svg_security_parse=OK")
print("four_semantic_snippets=OK")
print("registry_and_scss_namespaces=OK")
print("custom_frontend_javascript=ABSENT")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 3 static validation failed."
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
    if ($LASTEXITCODE -ne 0 -or $moduleState -notmatch "^website_webkit\|installed\|19\.0\.") {
        throw "An Odoo 19 website_webkit version is not installed."
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
from lxml import html

base = "http://127.0.0.1:8069"
snippet_ids = (
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
)
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

static_paths = [
    "/website_webkit/static/src/img/wbuilder/webkit_group.svg",
    "/website_webkit/static/src/img/demo/hero-workflows.svg",
    "/website_webkit/static/src/img/demo/sophie-lambert.svg",
] + [f"/website_webkit/static/src/img/wbuilder/{snippet_id}.svg" for snippet_id in snippet_ids]
for path in static_paths:
    response = session.get(base + path, timeout=30)
    assert response.status_code == 200, (path, response.status_code)

page = session.get(base + "/?debug=assets", timeout=30)
page.raise_for_status()
document = html.fromstring(page.content)
order = document.xpath('//div[@id="wrap"]/section/@data-snippet')
assert order == list(snippet_ids), order
assert len(document.xpath('//section[contains(@class,"s_webkit_features")]//*[contains(@class,"webkit_feature_card")]')) == 3

css_path = re.search(r'href="([^"]*web\.assets_frontend\.css)"', page.text).group(1)
css = session.get(base + css_path, timeout=90)
assert css.status_code == 200
assert "css_error_message" not in css.text
for snippet_id in snippet_ids:
    assert f".{snippet_id}" in css.text

print("static_assets_http=OK")
print("canonical_public_homepage=OK")
print("frontend_scss_bundle=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 3 HTTP validation failed."
    }
} finally {
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue
}

@'
from lxml import etree

snippet_ids = (
    "s_webkit_hero",
    "s_webkit_features",
    "s_webkit_trust",
    "s_webkit_cta",
)
registry = env.ref("website.snippets")
combined = etree.tostring(registry._get_combined_arch(), encoding="unicode")
assert combined.count('snippet-group="webkit"') == 1
for snippet_id in snippet_ids:
    assert combined.count(f't-snippet="website_webkit.{snippet_id}"') == 1
    view = env.ref(f"website_webkit.{snippet_id}")
    assert view.active and view.type == "qweb"

homepage = env["ir.ui.view"].search([
    ("key", "=", "website.homepage"),
    ("website_id", "!=", False),
], order="website_id, id", limit=1)
document = etree.fromstring(homepage.arch_db.encode())
order = document.xpath("//div[@id='wrap']/section/@data-snippet")
assert order == list(snippet_ids), order
print("combined_builder_registry=OK")
print("canonical_persisted_homepage=OK")
'@ | & $python $odooBin shell -c $config -d webkit_dev --no-http
if ($LASTEXITCODE -ne 0) {
    throw "The Stage 3 Odoo registry validation failed."
}

if ($Browser) {
    $playwright = Join-Path $runtime "browser-check\node_modules\playwright-core"
    if (-not (Test-Path -LiteralPath $playwright)) {
        throw "Playwright Core is missing from $playwright."
    }
    node (Join-Path $PSScriptRoot "verify-stage3-browser.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 3 browser acceptance test failed."
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

Write-Output "Stage 3 validation completed successfully."
