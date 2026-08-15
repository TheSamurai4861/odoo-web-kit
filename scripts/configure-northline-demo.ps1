[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Apply", "Verify", "Restore")]
    [string]$Action
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\dev-env.ps1")
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$workspace = $dev.Workspace
$runtime = $dev.Runtime
$python = $dev.Python
$odooBin = $dev.OdooBin
$config = $dev.Config
$script = Join-Path $PSScriptRoot "configure-northline-demo.py"

$env:WEBKIT_DEMO_ACTION = $Action.ToLowerInvariant()
$env:WEBKIT_DEMO_DATABASE = $dev.Database
$env:WEBKIT_DEMO_LOGO = Join-Path `
    $workspace `
    "website_webkit\static\src\img\demo\northline-logo.svg"
$env:WEBKIT_DEMO_STATE = Join-Path $runtime "northline-demo-original.json"
try {
    Get-Content -Raw -LiteralPath $script | & $python $odooBin shell `
        -c $config `
        -d $dev.Database `
        --db-filter="^$([regex]::Escape($dev.Database))`$" `
        --no-http
    if ($LASTEXITCODE -ne 0) {
        throw "Northline demo $Action failed."
    }

    if ($Action -eq "Verify") {
        try {
            $response = Invoke-WebRequest `
                -Uri "$($dev.BaseUrl)/" `
                -UseBasicParsing `
                -TimeoutSec 15
        } catch {
            throw "Northline database state is valid, but the public website could not be verified: $($_.Exception.Message)"
        }

        $required = @(
            "hello@northline.example",
            "Review a workflow",
            "A fictional Odoo workflow studio",
            "Northline demo",
            "Odoo Web Kit"
        )
        foreach ($marker in $required) {
            if (-not $response.Content.Contains($marker)) {
                throw "Northline public marker is missing: $marker. Restart Odoo to clear stale QWeb caches."
            }
        }

        $forbidden = @(
            "info@yourcompany.example.com",
            "+1 555-555-5556",
            "Company name",
            "passionate people"
        )
        foreach ($placeholder in $forbidden) {
            if ($response.Content.Contains($placeholder)) {
                throw "Generic public placeholder is still rendered: $placeholder"
            }
        }
        Write-Output "northline_demo_public_http=OK"
    }
} finally {
    Remove-Item Env:WEBKIT_DEMO_ACTION -ErrorAction SilentlyContinue
    Remove-Item Env:WEBKIT_DEMO_DATABASE -ErrorAction SilentlyContinue
    Remove-Item Env:WEBKIT_DEMO_LOGO -ErrorAction SilentlyContinue
    Remove-Item Env:WEBKIT_DEMO_STATE -ErrorAction SilentlyContinue
}
