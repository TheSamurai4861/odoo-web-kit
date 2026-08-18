Set-StrictMode -Version Latest

$script:WebKitIsWindows = $env:OS -eq "Windows_NT"
$uname = Get-Command uname -CommandType Application -ErrorAction SilentlyContinue
$script:WebKitIsMacOS = $uname -and (& $uname.Source) -eq "Darwin"

function Get-WebKitEnvironmentValue {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Default
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }
    return $value
}

function Resolve-WebKitExecutable {
    param(
        [Parameter(Mandatory)][string]$EnvironmentVariable,
        [Parameter(Mandatory)][string[]]$Commands,
        [string[]]$Candidates = @(),
        [switch]$ProbeVersion
    )

    function Test-WebKitExecutable {
        param([Parameter(Mandatory)][string]$Path)

        if (-not $ProbeVersion) {
            return $true
        }
        try {
            & $Path --version *> $null
            return $LASTEXITCODE -eq 0
        } catch {
            return $false
        }
    }

    $explicit = [Environment]::GetEnvironmentVariable($EnvironmentVariable)
    if (-not [string]::IsNullOrWhiteSpace($explicit)) {
        if (-not (Test-Path -LiteralPath $explicit -PathType Leaf)) {
            throw "$EnvironmentVariable points to a missing executable: $explicit"
        }
        if (-not (Test-WebKitExecutable -Path $explicit)) {
            throw "$EnvironmentVariable points to an unusable executable: $explicit"
        }
        return (Resolve-Path -LiteralPath $explicit).Path
    }

    foreach ($candidate in $Candidates) {
        if (
            $candidate -and
            (Test-Path -LiteralPath $candidate -PathType Leaf) -and
            (Test-WebKitExecutable -Path $candidate)
        ) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    foreach ($command in $Commands) {
        $resolved = Get-Command $command -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($resolved -and (Test-WebKitExecutable -Path $resolved.Source)) {
            return $resolved.Source
        }
    }
    return $null
}

function Get-WebKitPostgreSQLCandidates {
    param([Parameter(Mandatory)][string]$ExecutableName)

    $candidates = @()
    $explicitBin = [Environment]::GetEnvironmentVariable("WEBKIT_PG_BIN")
    if ($explicitBin) {
        $candidates += Join-Path $explicitBin $ExecutableName
    }
    if ($script:WebKitIsWindows) {
        foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
            if (-not $root) {
                continue
            }
            $postgresRoot = Join-Path $root "PostgreSQL"
            if (Test-Path -LiteralPath $postgresRoot -PathType Container) {
                $versions = Get-ChildItem -LiteralPath $postgresRoot -Directory |
                    Sort-Object { [double]($_.Name -replace '[^0-9.]', '') } -Descending
                foreach ($version in $versions) {
                    $candidates += Join-Path $version.FullName "bin\$ExecutableName"
                }
            }
        }
    }
    return $candidates
}

function Resolve-WebKitBrowser {
    $candidates = @()
    if ($script:WebKitIsWindows) {
        foreach ($root in @(${env:ProgramFiles(x86)}, $env:ProgramFiles, $env:LOCALAPPDATA)) {
            if ($root) {
                $candidates += Join-Path $root "Microsoft\Edge\Application\msedge.exe"
                $candidates += Join-Path $root "Google\Chrome\Application\chrome.exe"
            }
        }
    } elseif ($script:WebKitIsMacOS) {
        $candidates += "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
        $candidates += "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    }
    return Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_BROWSER_PATH" `
        -Commands @("msedge", "microsoft-edge", "google-chrome", "chromium", "chromium-browser") `
        -Candidates $candidates
}

function Get-WebKitDevEnvironment {
    param([Parameter(Mandatory)][string]$ScriptRoot)

    $workspace = (Resolve-Path (Split-Path -Parent $ScriptRoot)).Path
    $defaultOdooRoot = Split-Path -Parent $workspace
    $odooRoot = Get-WebKitEnvironmentValue "WEBKIT_ODOO_ROOT" $defaultOdooRoot
    $runtime = Get-WebKitEnvironmentValue "WEBKIT_RUNTIME" (Join-Path $odooRoot ".runtime")
    $odooSource = Get-WebKitEnvironmentValue "WEBKIT_ODOO_SOURCE" (Join-Path $odooRoot "odoo-19")

    $python = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_PYTHON" `
        -Commands @("python3", "python") `
        -Candidates @(
            (Join-Path $odooRoot ".venv-odoo19\Scripts\python.exe"),
            (Join-Path $odooRoot ".venv-odoo19/bin/python")
        ) `
        -ProbeVersion
    $odooBin = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_ODOO_BIN" `
        -Commands @("odoo-bin", "odoo") `
        -Candidates @((Join-Path $odooSource "odoo-bin"))

    $pgIsReady = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_PG_ISREADY" `
        -Commands @("pg_isready") `
        -Candidates (Get-WebKitPostgreSQLCandidates "pg_isready.exe")
    $psql = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_PSQL" `
        -Commands @("psql") `
        -Candidates (Get-WebKitPostgreSQLCandidates "psql.exe")
    $pgCtl = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_PG_CTL" `
        -Commands @("pg_ctl") `
        -Candidates (Get-WebKitPostgreSQLCandidates "pg_ctl.exe")
    $createdb = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_CREATEDB" `
        -Commands @("createdb") `
        -Candidates (Get-WebKitPostgreSQLCandidates "createdb.exe")
    $dropdb = Resolve-WebKitExecutable `
        -EnvironmentVariable "WEBKIT_DROPDB" `
        -Commands @("dropdb") `
        -Candidates (Get-WebKitPostgreSQLCandidates "dropdb.exe")
    $qaPort = [int](Get-WebKitEnvironmentValue "WEBKIT_QA_PORT" "8070")
    $qaBaseUrl = Get-WebKitEnvironmentValue "WEBKIT_QA_BASE_URL" "http://127.0.0.1:$qaPort"

    [pscustomobject]@{
        Workspace = $workspace
        OdooRoot = $odooRoot
        OdooSource = $odooSource
        Runtime = $runtime
        Python = $python
        OdooBin = $odooBin
        Config = Get-WebKitEnvironmentValue "WEBKIT_ODOO_CONFIG" (Join-Path $runtime "odoo-dev.conf")
        PgIsReady = $pgIsReady
        Psql = $psql
        PgCtl = $pgCtl
        Createdb = $createdb
        Dropdb = $dropdb
        PgData = Get-WebKitEnvironmentValue "WEBKIT_PG_DATA" (Join-Path $runtime "postgresql-16-webkit")
        PgHost = Get-WebKitEnvironmentValue "WEBKIT_PG_HOST" "127.0.0.1"
        PgPort = [int](Get-WebKitEnvironmentValue "WEBKIT_PG_PORT" "5433")
        DbUser = Get-WebKitEnvironmentValue "WEBKIT_DB_USER" "odoo_webkit"
        Database = Get-WebKitEnvironmentValue "WEBKIT_DB" "webkit_dev"
        BaseUrl = (Get-WebKitEnvironmentValue "WEBKIT_BASE_URL" "http://127.0.0.1:8069").TrimEnd("/")
        QaDatabase = Get-WebKitEnvironmentValue "WEBKIT_QA_DB" "webkit_qa_stage6"
        QaPort = $qaPort
        QaBaseUrl = $qaBaseUrl.TrimEnd("/")
        Browser = Resolve-WebKitBrowser
    }
}

function Assert-WebKitPath {
    param(
        [Parameter(Mandatory)][AllowNull()][string]$Path,
        [Parameter(Mandatory)][string]$Description,
        [ValidateSet("Leaf", "Container", "Any")][string]$Type = "Any"
    )

    $pathType = if ($Type -eq "Any") { "Any" } else { $Type }
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType $pathType)) {
        throw "$Description is missing. Configure its WEBKIT_* environment variable. Resolved value: $Path"
    }
}
