"""Validate the committed media contract for a candidate directory."""

from __future__ import annotations

import argparse
import struct
from pathlib import Path


EXPECTED_PNGS = {
    "homepage-desktop.png": (1440, 2000),
    "homepage-mobile.png": (390, 3000),
    "four-components.png": (1440, 1800),
    "website-builder.png": (1440, 1000),
    "web-kit-category.png": (1440, 1000),
    "hero-options.png": (1440, 1000),
}


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        if stream.read(8) != b"\x89PNG\r\n\x1a\n":
            raise AssertionError(f"Invalid PNG signature: {path}")
        length = struct.unpack(">I", stream.read(4))[0]
        if stream.read(4) != b"IHDR" or length != 13:
            raise AssertionError(f"Invalid PNG header: {path}")
        return struct.unpack(">II", stream.read(8))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    media = args.directory.resolve()
    if not media.is_dir():
        raise AssertionError(f"Media directory is missing: {media}")

    actual_pngs = {path.name for path in media.glob("*.png")}
    if actual_pngs != set(EXPECTED_PNGS):
        raise AssertionError(f"Unexpected PNG set: {sorted(actual_pngs)}")
    for name, (expected_width, minimum_height) in EXPECTED_PNGS.items():
        path = media / name
        width, height = png_dimensions(path)
        if width != expected_width or height < minimum_height:
            raise AssertionError(f"Unexpected dimensions for {name}: {width}x{height}")
        if not 20_000 <= path.stat().st_size <= 4_000_000:
            raise AssertionError(f"Unexpected file size for {name}: {path.stat().st_size}")

    video = media / "odoo-web-kit-demo.mp4"
    if not video.is_file() or not 500_000 <= video.stat().st_size <= 10_000_000:
        raise AssertionError("The MP4 is missing or outside its size budget")
    print("media_files=6_png|1_mp4")
    print("media_dimensions_and_budgets=OK")


if __name__ == "__main__":
    main()
