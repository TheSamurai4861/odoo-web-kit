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

# Stage 4 must preserve every functional guarantee established in Stage 3.
& (Join-Path $PSScriptRoot "verify-stage3.ps1") -Browser:$Browser

Push-Location $workspace
try {
    @'
import ast
import re
from pathlib import Path

from lxml import etree

root = Path("website_webkit")
manifest = ast.literal_eval((root / "__manifest__.py").read_text(encoding="utf-8"))
version = tuple(map(int, manifest["version"].split(".")))
assert version[:2] == (19, 0) and version >= (19, 0, 3, 0, 0)

hero = etree.parse(str(root / "views/snippets/s_webkit_hero.xml"))
trust = etree.parse(str(root / "views/snippets/s_webkit_trust.xml"))
cta = etree.parse(str(root / "views/snippets/s_webkit_cta.xml"))
assert len(hero.xpath("//div[contains(concat(' ', @class, ' '), ' col-xl-6 ')]")) == 2
assert len(trust.xpath("//div[contains(@class, 'col-xl-')]")) == 2
assert len(cta.xpath("//div[contains(@class, 'col-xl-')]")) == 2
assert hero.xpath("//div[contains(@class, 'g-4') and contains(@class, 'g-xl-5')]")
assert trust.xpath("//div[contains(@class, 'g-4') and contains(@class, 'g-xl-5')]")

scss_root = root / "static/src/scss"
scss = "\n".join(
    path.read_text(encoding="utf-8") for path in sorted(scss_root.glob("*.scss"))
)
assert not re.search(r"#[0-9a-fA-F]{3,8}\b", scss), "Hardcoded SCSS hex color found."
for token in (
    "$primary",
    "$body-color",
    "$white",
    "$spacer",
    "$border-radius-lg",
    "$border-radius-xl",
    "var(--o-color-1)",
):
    assert token in scss, token
for rule in (
    "prefers-reduced-motion: reduce",
    "hover: hover",
    "pointer: fine",
    "focus-visible",
    "overflow-wrap: anywhere",
    "text-wrap: balance",
    "media-breakpoint-down(xl)",
    "media-breakpoint-down(lg)",
    "media-breakpoint-down(sm)",
):
    assert rule in scss, rule
assert "min-height: 2.75rem" in scss
assert "box-shadow: 0 0 0 0.375rem $primary !important" in scss

print("stage4_manifest_version=OK")
print("responsive_template_contract=OK")
print("odoo_bootstrap_design_tokens=OK")
print("interaction_accessibility_rules=OK")
print("hardcoded_hex_colors=ABSENT")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 4 static validation failed."
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

page = session.get(base + "/?debug=assets", timeout=30)
page.raise_for_status()
document = html.fromstring(page.content)
assert len(document.xpath('//section[contains(@class,"s_webkit_hero")]//div[contains(@class,"col-xl-6")]')) == 2
assert len(document.xpath('//section[contains(@class,"s_webkit_trust")]//div[contains(@class,"col-xl-")]')) >= 2
assert len(document.xpath('//section[contains(@class,"s_webkit_cta")]//div[contains(@class,"col-xl-")]')) >= 2

css_path = re.search(r'href="([^"]*web\.assets_frontend\.css)"', page.text).group(1)
css = session.get(base + css_path, timeout=90)
assert css.status_code == 200
assert "css_error_message" not in css.text
for compiled_rule in (
    "@media (prefers-reduced-motion: reduce)",
    "@media (hover: hover) and (pointer: fine)",
    "overflow-wrap: anywhere",
    "text-wrap: balance",
    "outline: 0.1875rem solid #FFF",
):
    assert compiled_rule in css.text, compiled_rule

print("persisted_responsive_markup=OK")
print("compiled_product_styles=OK")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 4 HTTP/CSS validation failed."
    }
} finally {
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue
}

if ($Browser) {
    $playwright = Join-Path $runtime "browser-check\node_modules\playwright-core"
    if (-not (Test-Path -LiteralPath $playwright)) {
        throw "Playwright Core is missing from $playwright."
    }
    node (Join-Path $PSScriptRoot "verify-stage4-browser.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "The Stage 4 browser acceptance test failed."
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

Write-Output "Stage 4 validation completed successfully."
