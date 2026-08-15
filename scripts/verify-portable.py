"""Run repository checks that do not require an Odoo installation."""

from __future__ import annotations

import ast
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "website_webkit"
ALLOWED_SUFFIXES = {".js", ".py", ".scss", ".svg", ".xml"}
EXTERNAL_RESOURCE = re.compile(
    r"(?:href|src)\s*=\s*[\"']https?://|url\(\s*[\"']?https?://",
    re.IGNORECASE,
)
LOCAL_LINK = re.compile(r"!?\[[^]]*]\(([^)]+)\)")
FORBIDDEN_PLACEHOLDERS = (
    "+1 555-555-5556",
    "Company name",
    "info@yourcompany.example.com",
    "passionate people",
)
PUBLIC_DOCUMENTS = (
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "docs/architecture.md",
    "docs/case-study.md",
    "docs/testing.md",
)
TEXT_SUFFIXES = {".cjs", ".js", ".md", ".py", ".scss", ".svg", ".xml", ".yaml", ".yml"}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def package_files() -> list[Path]:
    return sorted(
        path
        for path in ADDON.rglob("*")
        if path.is_file() and "__pycache__" not in path.parts
    )


def public_text_files() -> list[Path]:
    candidates = [
        ROOT / name
        for name in (".editorconfig", ".gitattributes", ".gitignore", "LICENSE", *PUBLIC_DOCUMENTS)
    ]
    for directory in (ROOT / ".github", ROOT / "scripts", ADDON):
        candidates.extend(directory.rglob("*"))
    return sorted({
        path
        for path in candidates
        if path.is_file()
        and "__pycache__" not in path.parts
        and (
            path.name in {".editorconfig", ".gitattributes", ".gitignore", "LICENSE"}
            or path.suffix in TEXT_SUFFIXES
        )
    })


def verify_manifest(files: list[Path]) -> dict[str, object]:
    manifest_path = ADDON / "__manifest__.py"
    manifest = ast.literal_eval(manifest_path.read_text(encoding="utf-8"))
    require(manifest.get("name") == "Odoo Web Kit", "Unexpected addon name")
    require(manifest.get("version") == "19.0.5.0.0", "Unexpected addon version")
    require(manifest.get("license") == "LGPL-3", "Manifest must declare LGPL-3")
    require(manifest.get("depends") == ["website"], "Unexpected dependency set")
    require(manifest.get("installable") is True, "Addon must be installable")
    require(manifest.get("application") is False, "Addon must not be an application")

    for relative_path in manifest.get("data", []):
        require((ADDON / relative_path).is_file(), f"Missing data file: {relative_path}")

    frontend = manifest["assets"]["web.assets_frontend"]
    require(frontend and all(path.endswith(".scss") for path in frontend),
            "Frontend assets must contain SCSS only")
    for asset in frontend:
        prefix = "website_webkit/"
        require(asset.startswith(prefix), f"Unexpected asset namespace: {asset}")
        require((ROOT / asset).is_file(), f"Missing frontend asset: {asset}")
    require(not (ADDON / "static" / "src" / "js").exists(),
            "Public JavaScript is outside the addon contract")
    require(
        manifest["assets"].get("website.website_builder_assets")
        == ["website_webkit/static/src/builder/**/*"],
        "Unexpected Website Builder asset declaration",
    )
    require(any("builder" in path.parts for path in files), "Builder assets are missing")

    unexpected = [path.relative_to(ROOT) for path in files if path.suffix not in ALLOWED_SUFFIXES]
    require(not unexpected, f"Unexpected package files: {unexpected}")
    return manifest


def verify_sources(files: list[Path]) -> dict[str, int]:
    for path in files:
        source = path.read_text(encoding="utf-8")
        lowered = source.lower()
        require("<!doctype" not in lowered, f"DOCTYPE is forbidden: {path}")
        require("<!entity" not in lowered, f"ENTITY is forbidden: {path}")
        require("<script" not in lowered, f"Inline script is forbidden: {path}")
        require("javascript:" not in lowered, f"JavaScript URL is forbidden: {path}")
        require("<foreignobject" not in lowered, f"foreignObject is forbidden: {path}")
        require(not EXTERNAL_RESOURCE.search(source), f"External resource found: {path}")
        if path.suffix in {".svg", ".xml"}:
            ET.parse(path)
        elif path.suffix == ".py":
            ast.parse(source, filename=str(path))

    svg_files = [path for path in files if path.suffix == ".svg"]
    scss_files = [path for path in files if path.suffix == ".scss"]
    builder_files = [path for path in files if "builder" in path.parts]
    metrics = {
        "package_files": len(files),
        "package_bytes": sum(path.stat().st_size for path in files),
        "scss_bytes": sum(path.stat().st_size for path in scss_files),
        "svg_bytes": sum(path.stat().st_size for path in svg_files),
        "builder_bytes": sum(path.stat().st_size for path in builder_files),
    }
    require(metrics["package_bytes"] <= 65_536, "Addon exceeds the package budget")
    require(metrics["scss_bytes"] <= 16_384, "SCSS exceeds its budget")
    require(metrics["svg_bytes"] <= 16_384, "SVG files exceed their aggregate budget")
    require(all(path.stat().st_size <= 8_192 for path in svg_files),
            "An SVG exceeds its individual budget")
    require(metrics["builder_bytes"] <= 8_192, "Builder assets exceed their budget")
    return metrics


def verify_portable_sources(text_files: list[Path]) -> None:
    for path in text_files:
        data = path.read_bytes()
        require(not data.startswith(b"\xef\xbb\xbf"), f"UTF-8 BOM is forbidden: {path}")
        require(b"\r" not in data, f"Only LF line endings are allowed: {path}")
        require(data.endswith(b"\n"), f"Final newline is missing: {path}")
        require(
            not any(line.endswith((b" ", b"\t")) for line in data.splitlines()),
            f"Trailing whitespace found: {path}",
        )
        source = data.decode("utf-8")
        if path.suffix == ".py":
            ast.parse(source, filename=str(path))

    addon_text = "\n".join(path.read_text(encoding="utf-8") for path in package_files())
    for placeholder in FORBIDDEN_PLACEHOLDERS:
        require(placeholder not in addon_text, f"Forbidden placeholder found: {placeholder}")


def verify_repository_files() -> None:
    required = [
        ROOT / ".editorconfig",
        ROOT / ".gitattributes",
        ROOT / ".github" / "workflows" / "quality.yml",
        ROOT / "CHANGELOG.md",
        ROOT / "CONTRIBUTING.md",
        ROOT / "LICENSE",
        ROOT / "README.md",
        ROOT / "docs" / "architecture.md",
        ROOT / "docs" / "case-study.md",
        ROOT / "docs" / "testing.md",
    ]
    require(all(path.is_file() for path in required), "A required public document is missing")

    license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
    require("GNU LESSER GENERAL PUBLIC LICENSE" in license_text, "LICENSE is not LGPL")
    require("Version 3, 29 June 2007" in license_text, "LICENSE is not LGPL version 3")
    require("19.0.5.0.0" in (ROOT / "CHANGELOG.md").read_text(encoding="utf-8"),
            "Current version is absent from CHANGELOG.md")

    public_markdown = [ROOT / relative_path for relative_path in PUBLIC_DOCUMENTS]
    for markdown in public_markdown:
        source = markdown.read_text(encoding="utf-8")
        for target in LOCAL_LINK.findall(source):
            target = target.strip().strip("<>").split("#", 1)[0]
            if not target or re.match(r"^(?:https?|mailto):", target, re.IGNORECASE):
                continue
            require((markdown.parent / target).resolve().exists(),
                    f"Broken local link in {markdown.relative_to(ROOT)}: {target}")


def main() -> int:
    files = package_files()
    verify_manifest(files)
    metrics = verify_sources(files)
    verify_portable_sources(public_text_files())
    verify_repository_files()
    for name, value in metrics.items():
        print(f"{name}={value}")
    print("portable_checks=OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, OSError, SyntaxError, ET.ParseError) as error:
        print(f"portable_checks=FAILED: {error}", file=sys.stderr)
        raise SystemExit(1) from error
