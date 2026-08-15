[CmdletBinding()]
param(
    [switch]$IncludePostgreSQL
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\dev-env.ps1")
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$pgCtl = $dev.PgCtl
$pgData = $dev.PgData
$odooPort = ([Uri]$dev.BaseUrl).Port

$odooListeners = Get-NetTCPConnection -LocalPort $odooPort -State Listen -ErrorAction SilentlyContinue
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
