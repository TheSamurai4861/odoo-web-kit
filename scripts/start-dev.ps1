[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$runtime = Join-Path $odooRoot ".runtime"
$pgBin = "C:\Program Files\PostgreSQL\16\bin"
$pgData = Join-Path $runtime "postgresql-16-webkit"
$pgLog = Join-Path $runtime "postgresql-16-webkit.log"
$python = Join-Path $odooRoot ".venv-odoo19\Scripts\python.exe"
$odooBin = Join-Path $odooRoot "odoo-19\odoo-bin"
$config = Join-Path $runtime "odoo-dev.conf"

foreach ($requiredPath in @($pgBin, $pgData, $python, $odooBin, $config)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required path is missing: $requiredPath"
    }
}

$postgres = Get-NetTCPConnection -LocalPort 5433 -State Listen -ErrorAction SilentlyContinue
if (-not $postgres) {
    & (Join-Path $pgBin "pg_ctl.exe") -D $pgData -l $pgLog -o '"-p 5433 -h 127.0.0.1"' start
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL failed to start (exit code $LASTEXITCODE)."
    }
}

& (Join-Path $pgBin "pg_isready.exe") -h 127.0.0.1 -p 5433
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL is not ready on 127.0.0.1:5433."
}

$odoo = Get-NetTCPConnection -LocalPort 8069 -State Listen -ErrorAction SilentlyContinue
if ($odoo) {
    Write-Output "Odoo is already listening at http://127.0.0.1:8069."
    exit 0
}

$process = Start-Process `
    -FilePath $python `
    -ArgumentList @($odooBin, "-c", $config, "-d", "webkit_dev") `
    -WorkingDirectory (Split-Path -Parent $odooBin) `
    -WindowStyle Hidden `
    -PassThru

$deadline = (Get-Date).AddSeconds(60)
do {
    Start-Sleep -Milliseconds 500
    $odoo = Get-NetTCPConnection -LocalPort 8069 -State Listen -ErrorAction SilentlyContinue
    if ($odoo) {
        $listenerPid = ($odoo | Select-Object -First 1).OwningProcess
        Write-Output "Odoo started with PID ${listenerPid}: http://127.0.0.1:8069"
        exit 0
    }
    if ($process.HasExited) {
        throw "Odoo exited with code $($process.ExitCode). Check $runtime\odoo.log."
    }
} while ((Get-Date) -lt $deadline)

throw "Odoo did not listen on port 8069 within 60 seconds."
