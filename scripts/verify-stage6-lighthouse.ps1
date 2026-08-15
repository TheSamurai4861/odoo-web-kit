[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

. (Join-Path $PSScriptRoot "lib\dev-env.ps1")
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$runtime = $dev.Runtime
$report = Join-Path $runtime "stage6-lighthouse-desktop.json"
$launcherLog = Join-Path $runtime "stage6-lighthouse-launcher.log"
$browser = $dev.Browser
Assert-WebKitPath -Path $browser -Description "Chromium-based browser" -Type Leaf

npx --yes lighthouse "$($dev.BaseUrl)/" `
    --preset=desktop `
    --output=json `
    --output-path=$report `
    --chrome-path=$browser `
    --chrome-flags="--headless --no-sandbox --disable-gpu" `
    --only-categories=performance,accessibility,best-practices,seo `
    --quiet `
    2> $launcherLog
$lighthouseExit = $LASTEXITCODE

if (-not (Test-Path -LiteralPath $report)) {
    Get-Content -LiteralPath $launcherLog -ErrorAction SilentlyContinue
    throw "The Lighthouse report is absent."
}

$env:WEBKIT_LIGHTHOUSE_REPORT = $report
@'
const fs = require("fs");

const report = JSON.parse(fs.readFileSync(process.env.WEBKIT_LIGHTHOUSE_REPORT, "utf8"));
if (!report.categories || report.runtimeError) {
    throw new Error(`Incomplete Lighthouse report: ${JSON.stringify(report.runtimeError)}.`);
}
const audits = report.audits;
const scores = Object.fromEntries(
    Object.entries(report.categories).map(([key, value]) => [key, Math.round(value.score * 100)])
);
const requests = audits["network-requests"].details.items;
const webkitRequests = requests.filter((request) =>
    request.url.includes("/website_webkit/")
);
const failedAccessibility = report.categories.accessibility.auditRefs
    .map((reference) => audits[reference.id])
    .filter((audit) => audit && audit.score === 0);
const webkitAccessibilityFailures = failedAccessibility.flatMap((audit) =>
    (audit.details?.items || [])
        .filter((item) => JSON.stringify(item).includes("s_webkit"))
        .map(() => audit.id)
);
const evidence = {
    lighthouseVersion: report.lighthouseVersion,
    scores,
    metrics: {
        firstContentfulPaintMs: Math.round(audits["first-contentful-paint"].numericValue),
        largestContentfulPaintMs: Math.round(audits["largest-contentful-paint"].numericValue),
        totalBlockingTimeMs: Math.round(audits["total-blocking-time"].numericValue),
        cumulativeLayoutShift: audits["cumulative-layout-shift"].numericValue,
        fullPageTransferBytes: audits["total-byte-weight"].numericValue,
    },
    webkit: {
        requestCount: webkitRequests.length,
        transferBytes: webkitRequests.reduce(
            (total, request) => total + request.transferSize,
            0
        ),
        publicJavaScriptRequests: webkitRequests
            .filter((request) => request.resourceType === "Script")
            .map((request) => request.url),
        failedRequests: webkitRequests
            .filter((request) => request.statusCode >= 400)
            .map((request) => request.url),
        accessibilityFailures: webkitAccessibilityFailures,
    },
};
console.log(JSON.stringify(evidence, null, 2));

if (
    scores.performance < 70 ||
    scores.accessibility < 90 ||
    scores["best-practices"] < 90 ||
    scores.seo < 90
) {
    throw new Error(`Critical Lighthouse score: ${JSON.stringify(scores)}.`);
}
if (
    evidence.webkit.transferBytes > 10_000 ||
    evidence.webkit.publicJavaScriptRequests.length ||
    evidence.webkit.failedRequests.length ||
    evidence.webkit.accessibilityFailures.length
) {
    throw new Error(`Web Kit Lighthouse budget failed: ${JSON.stringify(evidence.webkit)}.`);
}
'@ | node
$reportExit = $LASTEXITCODE
Remove-Item Env:WEBKIT_LIGHTHOUSE_REPORT -ErrorAction SilentlyContinue
if ($reportExit -ne 0) {
    throw "The Lighthouse report assertions failed."
}

if ($lighthouseExit -ne 0) {
    # PowerShell can wrap the temporary path over several physical lines. The
    # report itself has already been parsed and all its assertions have passed,
    # so only Chrome Launcher's known post-report Windows cleanup failure is
    # tolerated here.
    $launcherText = Get-Content `
        -LiteralPath $launcherLog `
        -Raw `
        -ErrorAction SilentlyContinue
    $knownCleanupFailure =
        $launcherText -match "EPERM, Permission denied" -and
        $launcherText -match "Temp[\\/]lighthouse\."
    if (-not $knownCleanupFailure) {
        $launcherText
        throw "Lighthouse failed for a reason other than the known Windows profile cleanup issue."
    }
    Write-Output "lighthouse_launcher_cleanup=EPERM (report complete and validated)"
}

Write-Output "lighthouse_report=$report"
Write-Output "Stage 6 Lighthouse validation completed successfully."
