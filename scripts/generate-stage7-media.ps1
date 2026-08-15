[CmdletBinding()]
param(
    [string]$RepositoryUrl
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\dev-env.ps1")
$dev = Get-WebKitDevEnvironment -ScriptRoot $PSScriptRoot
$workspace = $dev.Workspace
$runtime = $dev.Runtime
$rawVideo = Join-Path $runtime "stage7-demo-raw.webm"
$media = Join-Path $workspace "docs\media"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$candidate = Join-Path $runtime "stage7-media-candidate-$timestamp-$PID"
$backup = Join-Path $runtime "stage7-media-backup-$timestamp"
$mediaFiles = @(
    "homepage-desktop.png",
    "homepage-mobile.png",
    "four-components.png",
    "website-builder.png",
    "web-kit-category.png",
    "hero-options.png",
    "odoo-web-kit-demo.mp4"
)

if (-not $RepositoryUrl) {
    $RepositoryUrl = [Environment]::GetEnvironmentVariable("WEBKIT_REPOSITORY_URL")
}
if (-not $RepositoryUrl) {
    $remotes = @(git -C $workspace remote)
    if ($remotes -contains "origin") {
        $RepositoryUrl = git -C $workspace remote get-url origin
    }
}
if ($RepositoryUrl -match '^git@github\.com:(.+?)(?:\.git)?$') {
    $RepositoryUrl = "https://github.com/$($Matches[1] -replace '\.git$', '')"
}
$RepositoryUrl = $RepositoryUrl -replace '\.git$', ''
if ($RepositoryUrl -notmatch '^https://github\.com/[^/\s]+/[^/\s]+$') {
    throw "Provide the public GitHub repository URL with -RepositoryUrl or configure origin."
}

foreach ($tool in @("node", "ffmpeg", "ffprobe")) {
    if (-not (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "Required media tool is missing: $tool"
    }
}
New-Item -ItemType Directory -Path $candidate | Out-Null
$env:WEBKIT_MEDIA_DIR = $candidate
$env:WEBKIT_REPOSITORY_URL = $RepositoryUrl
if (Test-Path -LiteralPath $rawVideo -PathType Leaf) {
    Remove-Item -LiteralPath $rawVideo -Force
}

try {
    node (Join-Path $PSScriptRoot "capture-stage7-media.cjs")
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 7 screenshot capture failed."
    }

    node (Join-Path $PSScriptRoot "record-stage7-demo.cjs")
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $rawVideo)) {
        throw "Stage 7 browser recording failed."
    }

    $candidateVideo = Join-Path $candidate "odoo-web-kit-demo.mp4"
    ffmpeg -hide_banner -loglevel error -y `
        -i $rawVideo `
        -vf "fps=30,scale=1280:720:flags=lanczos" `
        -c:v libx264 `
        -preset medium `
        -crf 24 `
        -pix_fmt yuv420p `
        -metadata "comment=Repository: $RepositoryUrl" `
        -movflags +faststart `
        -an `
        $candidateVideo
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 7 MP4 encoding failed."
    }

    & $dev.Python (Join-Path $PSScriptRoot "verify-media.py") $candidate
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 7 candidate media validation failed."
    }
    $probe = ffprobe -v error `
        -select_streams v:0 `
        -show_entries "stream=codec_name,width,height,pix_fmt:format=duration,size:format_tags=comment" `
        -of json `
        $candidateVideo | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 7 video probing failed."
    }
    $stream = $probe.streams | Select-Object -First 1
    $candidateRepositoryEvidence = ""
    if ($null -ne $probe.format.tags) {
        $commentProperty = $probe.format.tags.PSObject.Properties |
            Where-Object { $_.Name -eq "comment" } |
            Select-Object -First 1
        if ($null -ne $commentProperty) {
            $candidateRepositoryEvidence = [string]$commentProperty.Value
        }
    }
    $duration = [double]::Parse(
        $probe.format.duration,
        [Globalization.CultureInfo]::InvariantCulture
    )
    if (
        $duration -lt 60 -or $duration -gt 90 -or
        $stream.codec_name -ne "h264" -or
        $stream.width -ne 1280 -or
        $stream.height -ne 720 -or
        $stream.pix_fmt -ne "yuv420p" -or
        $candidateRepositoryEvidence -ne "Repository: $RepositoryUrl"
    ) {
        throw "The Stage 7 candidate video does not meet its delivery contract."
    }

    New-Item -ItemType Directory -Path $backup | Out-Null
    foreach ($name in $mediaFiles) {
        $current = Join-Path $media $name
        $replacement = Join-Path $candidate $name
        if (-not (Test-Path -LiteralPath $replacement -PathType Leaf)) {
            throw "Candidate media is missing: $replacement"
        }
        if (Test-Path -LiteralPath $current -PathType Leaf) {
            Copy-Item -LiteralPath $current -Destination (Join-Path $backup $name)
        }
    }
    try {
        foreach ($name in $mediaFiles) {
            Copy-Item `
                -LiteralPath (Join-Path $candidate $name) `
                -Destination (Join-Path $media $name) `
                -Force
        }
        foreach ($name in $mediaFiles) {
            $candidateHash = (Get-FileHash -Algorithm SHA256 (Join-Path $candidate $name)).Hash
            $publishedHash = (Get-FileHash -Algorithm SHA256 (Join-Path $media $name)).Hash
            if ($candidateHash -ne $publishedHash) {
                throw "Published media differs from its candidate: $name"
            }
        }
    } catch {
        foreach ($name in $mediaFiles) {
            $saved = Join-Path $backup $name
            if (Test-Path -LiteralPath $saved -PathType Leaf) {
                Copy-Item -LiteralPath $saved -Destination (Join-Path $media $name) -Force
            }
        }
        throw
    }
    Remove-Item -LiteralPath $rawVideo -Force
    Write-Output "repository_url=$RepositoryUrl"
    Write-Output ("video={0:N3}s|{1}|{2}x{3}|{4}" -f `
        $duration, $stream.codec_name, $stream.width, $stream.height, $stream.pix_fmt)
    Write-Output "media_candidate=$candidate"
    Write-Output "media_backup=$backup"
    Write-Output "Stage 7 media generation completed successfully."
} finally {
    Remove-Item Env:WEBKIT_MEDIA_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:WEBKIT_REPOSITORY_URL -ErrorAction SilentlyContinue
}
