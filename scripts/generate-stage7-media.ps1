[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$runtime = Join-Path $odooRoot ".runtime"
$rawVideo = Join-Path $runtime "stage7-demo-raw.webm"
$media = Join-Path $workspace "docs\media"
$finalVideo = Join-Path $media "odoo-web-kit-demo.mp4"

node (Join-Path $PSScriptRoot "capture-stage7-media.cjs")
if ($LASTEXITCODE -ne 0) {
    throw "Stage 7 screenshot capture failed."
}

node (Join-Path $PSScriptRoot "record-stage7-demo.cjs")
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $rawVideo)) {
    throw "Stage 7 browser recording failed."
}

ffmpeg -hide_banner -loglevel error -y `
    -i $rawVideo `
    -vf "fps=30,scale=1280:720:flags=lanczos" `
    -c:v libx264 `
    -preset medium `
    -crf 24 `
    -pix_fmt yuv420p `
    -movflags +faststart `
    -an `
    $finalVideo
if ($LASTEXITCODE -ne 0) {
    throw "Stage 7 MP4 encoding failed."
}

$probe = ffprobe -v error `
    -select_streams v:0 `
    -show_entries "stream=codec_name,width,height,pix_fmt:format=duration,size" `
    -of json `
    $finalVideo
if ($LASTEXITCODE -ne 0) {
    throw "Stage 7 video probing failed."
}
$probe
Write-Output "Stage 7 media generation completed successfully."
