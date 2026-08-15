[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$runtime = Join-Path $odooRoot ".runtime"
$python = Join-Path $odooRoot ".venv-odoo19\Scripts\python.exe"
$pgBin = "C:\Program Files\PostgreSQL\16\bin"
$dbPasswordFile = Join-Path $runtime "secrets\odoo-db-password"
$adminPasswordFile = Join-Path $runtime "secrets\odoo-admin-password"

foreach ($requiredPath in @($python, $dbPasswordFile, $adminPasswordFile)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required path is missing: $requiredPath"
    }
}

& $python --version
& $python -m pip check
if ($LASTEXITCODE -ne 0) {
    throw "The Python environment has broken dependencies."
}

& (Join-Path $pgBin "pg_isready.exe") -h 127.0.0.1 -p 5433
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL is not ready."
}

$env:PGPASSWORD = [IO.File]::ReadAllText($dbPasswordFile).Trim()
try {
    & (Join-Path $pgBin "psql.exe") `
        -X -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p 5433 `
        -U odoo_webkit -d webkit_dev `
        -At -c "select current_user, current_database(), current_setting('server_version');"
    if ($LASTEXITCODE -ne 0) {
        throw "The application database check failed."
    }
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

$env:WEBKIT_ODOO_ADMIN_PASSWORD = [IO.File]::ReadAllText($adminPasswordFile).Trim()
try {
    @'
import os
import requests

base = "http://127.0.0.1:8069"
session = requests.Session()
payload = {
    "jsonrpc": "2.0",
    "method": "call",
    "params": {
        "db": "webkit_dev",
        "login": "admin",
        "password": os.environ["WEBKIT_ODOO_ADMIN_PASSWORD"],
    },
    "id": 1,
}
response = session.post(base + "/web/session/authenticate", json=payload, timeout=30)
result = response.json().get("result") or {}
if response.status_code != 200 or not result.get("uid"):
    raise SystemExit("Odoo authentication failed.")

checks = {
    "homepage": "/",
    "backend_debug": "/odoo?debug=assets",
    "website_editor": "/@/?enable_editor=1&debug=assets",
}
for name, path in checks.items():
    page = session.get(base + path, allow_redirects=True, timeout=30)
    if page.status_code != 200 or "/web/login" in page.url:
        raise SystemExit(f"{name} failed: {page.status_code} {page.url}")
    print(f"{name}=OK ({page.url})")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "The HTTP validation failed."
    }
} finally {
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue
}

$log = Join-Path $runtime "odoo.log"
$lastStart = Select-String -LiteralPath $log -Pattern "Odoo version 19.0" |
    Select-Object -Last 1
if (-not $lastStart) {
    throw "No Odoo 19 server start marker was found in the log."
}
$currentLog = Get-Content -LiteralPath $log | Select-Object -Skip ($lastStart.LineNumber - 1)
$errors = $currentLog |
    Select-String -Pattern " ERROR | CRITICAL |Traceback" |
    Where-Object {
        $_.Line -notmatch "odoo\.sql_db: bad query:.*WITH visitor AS"
    }
$visitorRetries = $currentLog |
    Select-String -Pattern "SERIALIZATION_FAILURE, [1-9][0-9]* tries left"
if ($visitorRetries) {
    Write-Output "website_visitor_serialization_retries=$($visitorRetries.Count) (recovered by Odoo)"
}
if ($errors) {
    throw "Errors were found in the Odoo log."
}

Write-Output "Environment validation completed successfully."
