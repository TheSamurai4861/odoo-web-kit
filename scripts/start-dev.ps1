[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$environmentModule = Join-Path $PSScriptRoot "lib\dev-env.ps1"
. $environmentModule
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$runtime = $dev.Runtime
$pgData = $dev.PgData
$pgLog = Join-Path $runtime "postgresql-16-webkit.log"
$python = $dev.Python
$odooBin = $dev.OdooBin
$config = $dev.Config
$pgCtl = $dev.PgCtl
$pgIsReady = $dev.PgIsReady
$odooPort = ([Uri]$dev.BaseUrl).Port

foreach ($requiredPath in @($pgData, $python, $odooBin, $config, $pgCtl, $pgIsReady)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required path is missing: $requiredPath"
    }
}

$postgres = Get-NetTCPConnection -LocalPort $dev.PgPort -State Listen -ErrorAction SilentlyContinue
if (-not $postgres) {
    & $pgCtl -D $pgData -l $pgLog -o "`"-p $($dev.PgPort) -h $($dev.PgHost)`"" start
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL failed to start (exit code $LASTEXITCODE)."
    }
}

& $pgIsReady -h $dev.PgHost -p $dev.PgPort
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL is not ready on $($dev.PgHost):$($dev.PgPort)."
}

$odoo = Get-NetTCPConnection -LocalPort $odooPort -State Listen -ErrorAction SilentlyContinue
if ($odoo) {
    Write-Output "Odoo is already listening at $($dev.BaseUrl)."
    exit 0
}

$process = Start-Process `
    -FilePath $python `
    -ArgumentList @($odooBin, "-c", $config, "-d", $dev.Database) `
    -WorkingDirectory (Split-Path -Parent $odooBin) `
    -WindowStyle Hidden `
    -PassThru

$deadline = (Get-Date).AddSeconds(60)
do {
    Start-Sleep -Milliseconds 500
    $odoo = Get-NetTCPConnection -LocalPort $odooPort -State Listen -ErrorAction SilentlyContinue
    if ($odoo) {
        $listenerPid = ($odoo | Select-Object -First 1).OwningProcess
        Write-Output "Odoo started with PID ${listenerPid}: $($dev.BaseUrl)"
        exit 0
    }
    if ($process.HasExited) {
        throw "Odoo exited with code $($process.ExitCode). Check $runtime\odoo.log."
    }
} while ((Get-Date) -lt $deadline)

throw "Odoo did not listen on port $odooPort within 60 seconds."
