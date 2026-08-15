[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$runtime = Join-Path $odooRoot ".runtime"
$python = Join-Path $odooRoot ".venv-odoo19\Scripts\python.exe"
$odooBin = Join-Path $odooRoot "odoo-19\odoo-bin"
$config = Join-Path $runtime "odoo-dev.conf"
$pgBin = "C:\Program Files\PostgreSQL\16\bin"
$qaDatabase = "webkit_qa_stage6"
$qaPort = 8070
$qaLog = Join-Path $runtime "stage6-lifecycle-$PID.log"
$databaseCreated = $false
$qaServerPid = $null

if ($qaDatabase -ne "webkit_qa_stage6" -or $qaDatabase -eq "webkit_dev") {
    throw "Unsafe Stage 6 database target."
}
if (Get-NetTCPConnection -LocalPort $qaPort -State Listen -ErrorAction SilentlyContinue) {
    throw "QA port $qaPort is already in use."
}

function Stop-QaServer {
    if ($script:qaServerPid) {
        Stop-Process -Id $script:qaServerPid -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $script:qaServerPid -ErrorAction SilentlyContinue
        $script:qaServerPid = $null
    }
}

function Invoke-QaShell {
    param([Parameter(Mandatory)][string]$Source)

    $Source | & $python $odooBin shell `
        -c $config `
        -d $qaDatabase `
        --db-filter="^$qaDatabase`$" `
        --logfile=$qaLog `
        --no-http
    if ($LASTEXITCODE -ne 0) {
        throw "QA Odoo shell validation failed."
    }
}

try {
    $env:PGPASSWORD = [IO.File]::ReadAllText(
        (Join-Path $runtime "secrets\odoo-db-password")
    ).Trim()
    $existing = & (Join-Path $pgBin "psql.exe") `
        -X -h 127.0.0.1 -p 5433 `
        -U odoo_webkit -d postgres `
        -At -c "select 1 from pg_database where datname='$qaDatabase';"
    if ($existing -eq "1") {
        throw "QA database already exists; refusing to overwrite $qaDatabase."
    }
    & (Join-Path $pgBin "createdb.exe") `
        -h 127.0.0.1 -p 5433 `
        -U odoo_webkit -T template0 -E UTF8 `
        $qaDatabase
    if ($LASTEXITCODE -ne 0) {
        throw "QA database creation failed."
    }
    $databaseCreated = $true
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

    & $python $odooBin `
        -c $config `
        -d $qaDatabase `
        --db-filter="^$qaDatabase`$" `
        --logfile=$qaLog `
        -i website_webkit `
        --without-demo `
        --stop-after-init
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh website_webkit installation failed."
    }

    $env:WEBKIT_ODOO_ADMIN_PASSWORD = [IO.File]::ReadAllText(
        (Join-Path $runtime "secrets\odoo-admin-password")
    ).Trim()
    Invoke-QaShell -Source @'
import os
from lxml import etree

module = env["ir.module.module"].search([("name", "=", "website_webkit")], limit=1)
assert module.state == "installed" and module.latest_version == "19.0.4.0.0"
for xmlid in ("s_webkit_hero", "s_webkit_features", "s_webkit_trust", "s_webkit_cta"):
    view = env.ref(f"website_webkit.{xmlid}")
    assert view.active and view.type == "qweb"
combined = etree.tostring(env.ref("website.snippets")._get_combined_arch(), encoding="unicode")
assert combined.count('snippet-group="webkit"') == 1
for xmlid in ("s_webkit_hero", "s_webkit_features", "s_webkit_trust", "s_webkit_cta"):
    assert combined.count(f't-snippet="website_webkit.{xmlid}"') == 1
env.ref("base.user_admin").write({"password": os.environ["WEBKIT_ODOO_ADMIN_PASSWORD"]})
env.cr.commit()
print("fresh_install=installed|19.0.4.0.0")
print("fresh_registry=four_snippets")
'@
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue

    $process = Start-Process `
        -FilePath $python `
        -ArgumentList @(
            $odooBin, "-c", $config, "-d", $qaDatabase,
            "--db-filter=^$qaDatabase`$", "--http-port=$qaPort", "--logfile=$qaLog"
        ) `
        -WorkingDirectory (Split-Path -Parent $odooBin) `
        -WindowStyle Hidden `
        -PassThru
    $deadline = (Get-Date).AddSeconds(60)
    do {
        Start-Sleep -Milliseconds 500
        $listener = Get-NetTCPConnection `
            -LocalPort $qaPort -State Listen `
            -ErrorAction SilentlyContinue
        if ($listener) {
            $qaServerPid = ($listener | Select-Object -First 1).OwningProcess
            break
        }
        if ($process.HasExited) {
            throw "QA Odoo exited with code $($process.ExitCode)."
        }
    } while ((Get-Date) -lt $deadline)
    if (-not $qaServerPid) {
        throw "QA Odoo did not listen on port $qaPort."
    }

    # A listening socket precedes registry/routing readiness. Warm the standard
    # web bundle before Playwright opens the editor so cold asset compilation is
    # not charged against the browser navigation timeout.
    $httpDeadline = (Get-Date).AddSeconds(120)
    $httpReady = $false
    do {
        try {
            $response = Invoke-WebRequest `
                -Uri "http://127.0.0.1:$qaPort/web/login?db=$qaDatabase" `
                -UseBasicParsing `
                -TimeoutSec 15
            if ($response.StatusCode -eq 200) {
                $httpReady = $true
                break
            }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    } while ((Get-Date) -lt $httpDeadline)
    if (-not $httpReady) {
        throw "QA Odoo did not become HTTP-ready on port $qaPort."
    }
    Write-Output "qa_http_readiness=OK"

    node (Join-Path $PSScriptRoot "verify-stage6-fresh-browser.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh database browser acceptance failed."
    }
    Stop-QaServer

    & $python $odooBin `
        -c $config `
        -d $qaDatabase `
        --db-filter="^$qaDatabase`$" `
        --logfile=$qaLog `
        -u website_webkit `
        --stop-after-init
    if ($LASTEXITCODE -ne 0) {
        throw "QA module upgrade failed."
    }
    Invoke-QaShell -Source @'
from lxml import etree

module = env["ir.module.module"].search([("name", "=", "website_webkit")], limit=1)
assert module.state == "installed" and module.latest_version == "19.0.4.0.0"
homepage = env["ir.ui.view"].search([
    ("key", "=", "website.homepage"),
    ("website_id", "!=", False),
], limit=1)
document = etree.fromstring(homepage.arch_db.encode())
heroes = document.xpath(
    '//section[contains(concat(" ", normalize-space(@class), " "), " s_webkit_hero ")]'
)
assert len(heroes) == 1
classes = set(heroes[0].get("class", "").split())
assert "webkit_hero_align_center" in classes
assert "webkit_hero_align_start" not in classes
print("upgrade=customized_homepage_preserved")
'@

    Invoke-QaShell -Source @'
module = env["ir.module.module"].search([("name", "=", "website_webkit")], limit=1)
module.button_immediate_uninstall()
env.cr.commit()
module = env["ir.module.module"].search([("name", "=", "website_webkit")], limit=1)
assert module.state == "uninstalled"
assert not env["ir.model.data"].search_count([("module", "=", "website_webkit")])
assert not env["ir.ui.view"].search_count([("key", "like", "website_webkit.%")])
print("uninstall=views_and_external_ids_removed")
'@

    & $python $odooBin `
        -c $config `
        -d $qaDatabase `
        --db-filter="^$qaDatabase`$" `
        --logfile=$qaLog `
        -i website_webkit `
        --without-demo `
        --stop-after-init
    if ($LASTEXITCODE -ne 0) {
        throw "QA module reinstall failed."
    }
    Invoke-QaShell -Source @'
from lxml import etree

module = env["ir.module.module"].search([("name", "=", "website_webkit")], limit=1)
assert module.state == "installed" and module.latest_version == "19.0.4.0.0"
for xmlid in ("s_webkit_hero", "s_webkit_features", "s_webkit_trust", "s_webkit_cta"):
    assert env.ref(f"website_webkit.{xmlid}").active
homepage = env["ir.ui.view"].search([
    ("key", "=", "website.homepage"),
    ("website_id", "!=", False),
], limit=1)
document = etree.fromstring(homepage.arch_db.encode())
heroes = document.xpath(
    '//section[contains(concat(" ", normalize-space(@class), " "), " s_webkit_hero ")]'
)
assert len(heroes) == 1
assert "webkit_hero_align_center" in heroes[0].get("class", "").split()
print("reinstall=four_views_and_user_page_preserved")
'@

    $currentLog = Get-Content -LiteralPath $qaLog
    $issues = $currentLog |
        Select-String -Pattern " ERROR | CRITICAL |Traceback" |
        Where-Object {
            $_.Line -notmatch "odoo\.sql_db: bad query:.*WITH visitor AS"
        }
    if ($issues) {
        $issues
        throw "Errors were found in the QA lifecycle log."
    }
    Write-Output "qa_log=$qaLog"
    Write-Output "Stage 6 lifecycle validation completed successfully."
} finally {
    Stop-QaServer
    Remove-Item Env:WEBKIT_ODOO_ADMIN_PASSWORD -ErrorAction SilentlyContinue
    if ($databaseCreated) {
        $env:PGPASSWORD = [IO.File]::ReadAllText(
            (Join-Path $runtime "secrets\odoo-db-password")
        ).Trim()
        & (Join-Path $pgBin "dropdb.exe") `
            -h 127.0.0.1 -p 5433 `
            -U odoo_webkit `
            --force `
            $qaDatabase
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to remove QA database $qaDatabase."
        } else {
            Write-Output "qa_database_cleanup=OK"
        }
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    }
}
