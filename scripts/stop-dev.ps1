[CmdletBinding()]
param(
    [switch]$IncludePostgreSQL
)

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$runtime = Join-Path $odooRoot ".runtime"
$pgCtl = "C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe"
$pgData = Join-Path $runtime "postgresql-16-webkit"

$odooListeners = Get-NetTCPConnection -LocalPort 8069 -State Listen -ErrorAction SilentlyContinue
foreach ($listener in $odooListeners) {
    $process = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    if ($process -and $process.ProcessName -eq "python") {
        Stop-Process -Id $process.Id
        Wait-Process -Id $process.Id -Timeout 15 -ErrorAction SilentlyContinue
        Write-Output "Stopped Odoo process $($process.Id)."
    }
}

if ($IncludePostgreSQL) {
    if (-not (Test-Path -LiteralPath $pgCtl) -or -not (Test-Path -LiteralPath $pgData)) {
        throw "The dedicated PostgreSQL installation was not found."
    }
    & $pgCtl -D $pgData stop -m fast
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL failed to stop (exit code $LASTEXITCODE)."
    }
}
