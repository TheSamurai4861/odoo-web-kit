[CmdletBinding()]
param(
    [switch]$Full,
    [switch]$RegenerateMedia
)

$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$odooRoot = Split-Path -Parent $workspace
$python = Join-Path $odooRoot ".venv-odoo19\Scripts\python.exe"
$video = Join-Path $workspace "docs\media\odoo-web-kit-demo.mp4"

& (Join-Path $PSScriptRoot "verify-stage6.ps1") -Full:$Full

if ($RegenerateMedia) {
    & (Join-Path $PSScriptRoot "generate-stage7-media.ps1")
}

Push-Location $workspace
try {
    foreach ($script in Get-ChildItem scripts -File -Include "*.js", "*.cjs" -Recurse) {
        node --check $script.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "Invalid JavaScript: $($script.FullName)"
        }
    }

    @'
import os
import re
import struct
from pathlib import Path

root = Path.cwd()
readme = (root / "README.md").read_text(encoding="utf-8")
case_study = (root / "docs/case-study.md").read_text(encoding="utf-8")
architecture = (root / "docs/architecture.md").read_text(encoding="utf-8")
testing = (root / "docs/testing.md").read_text(encoding="utf-8")

required_sections = (
    "# Odoo Web Kit",
    "## Why",
    "## Components",
    "## Install",
    "## Use",
    "## Architecture",
    "## Design and accessibility",
    "## Quality evidence",
    "## Screenshots",
    "## Next steps",
)
for section in required_sections:
    assert section in readme, section
for public_document in ("case-study.md", "architecture.md", "testing.md"):
    assert public_document in readme, public_document
assert "# Case study" in case_study
assert "# Architecture" in architecture
assert "# Testing and acceptance" in testing

markdown_files = [
    root / "README.md",
    root / "docs/case-study.md",
    root / "docs/architecture.md",
    root / "docs/testing.md",
]
missing_links = []
for document in markdown_files:
    text = document.read_text(encoding="utf-8")
    for target in re.findall(r"\[[^]]+\]\(([^)#]+)(?:#[^)]+)?\)", text):
        if "://" in target or target.startswith("mailto:"):
            continue
        resolved = (document.parent / target).resolve()
        if not resolved.exists():
            missing_links.append((str(document.relative_to(root)), target))
assert not missing_links, missing_links

expected_pngs = {
    "homepage-desktop.png": (1440, 2000),
    "homepage-mobile.png": (390, 3000),
    "four-components.png": (1440, 1800),
    "website-builder.png": (1440, 1000),
    "web-kit-category.png": (1440, 1000),
    "hero-options.png": (1440, 1000),
}
media = root / "docs/media"
actual_pngs = {path.name for path in media.glob("*.png")}
assert actual_pngs == set(expected_pngs), actual_pngs

def png_dimensions(path):
    with path.open("rb") as stream:
        assert stream.read(8) == b"\x89PNG\r\n\x1a\n", path
        length = struct.unpack(">I", stream.read(4))[0]
        assert stream.read(4) == b"IHDR" and length == 13, path
        return struct.unpack(">II", stream.read(8))

for name, (expected_width, minimum_height) in expected_pngs.items():
    path = media / name
    width, height = png_dimensions(path)
    assert width == expected_width, (name, width)
    assert height >= minimum_height, (name, height)
    assert 20_000 <= path.stat().st_size <= 4_000_000, (name, path.stat().st_size)

video = media / "odoo-web-kit-demo.mp4"
assert video.is_file()
assert 500_000 <= video.stat().st_size <= 10_000_000, video.stat().st_size
assert "81-second product demo" in readme
assert "80.567 seconds" in testing

print("readme_structure=OK")
print("public_documentation=case-study|architecture|testing")
print("documentation_links=OK")
print("stage7_screenshots=6|dimensions_and_budgets=OK")
print(f"demo_video_bytes={video.stat().st_size}")
'@ | & $python -
    if ($LASTEXITCODE -ne 0) {
        throw "Stage 7 documentation or media audit failed."
    }

    $probe = ffprobe -v error `
        -select_streams v:0 `
        -show_entries "stream=codec_name,width,height,pix_fmt:format=duration,size" `
        -of json `
        $video | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to probe the Stage 7 demo video."
    }
    $stream = $probe.streams | Select-Object -First 1
    $duration = [double]::Parse(
        $probe.format.duration,
        [Globalization.CultureInfo]::InvariantCulture
    )
    if (
        $duration -lt 60 -or $duration -gt 90 -or
        $stream.codec_name -ne "h264" -or
        $stream.width -ne 1280 -or
        $stream.height -ne 720 -or
        $stream.pix_fmt -ne "yuv420p"
    ) {
        throw "The Stage 7 demo video does not meet the delivery contract."
    }
    Write-Output (
        "demo_video={0:N3}s|{1}|{2}x{3}|{4}" -f
        $duration, $stream.codec_name, $stream.width, $stream.height, $stream.pix_fmt
    )

    if (-not (Test-Path -LiteralPath ".git" -PathType Container)) {
        throw "The delivery workspace is not a Git repository."
    }
    $branch = git branch --show-current
    $commitCount = [int](git rev-list --count HEAD)
    if ($LASTEXITCODE -ne 0 -or $branch -ne "main" -or $commitCount -lt 1) {
        throw "The Git delivery history is invalid."
    }
    if ($Full) {
        $changes = @(git status --porcelain --untracked-files=all)
        if ($changes.Count -ne 0) {
            $changes
            throw "The Stage 7 delivery repository is not clean."
        }
        if ($commitCount -lt 2) {
            throw "The Stage 7 delivery requires at least two meaningful commits."
        }
    }
    Write-Output "git_delivery=branch:$branch|commits:$commitCount|clean_required:$Full"
} finally {
    Pop-Location
}

Write-Output "Stage 7 delivery validation completed successfully."
