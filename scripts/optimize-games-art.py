#!/usr/bin/env python3
"""Write WebP and AVIF derivatives for assets/games.

Drop a new canonical PNG in place, then rerun from the repo root:

    python3 scripts/optimize-games-art.py

Canonical files (these names are what the pages expect):

    assets/games/<slug>/icon-512.png
    assets/games/<slug>/feature-1024x500.png
    assets/games/<slug>/title-logo.png          optional
    assets/games/<slug>/shots/<name>.png

Derivatives written beside them:

    icon-512.webp / .avif and icon-256.webp / .avif
    feature-1024x500.webp / .avif and feature-w640.webp / .avif
    title-logo.webp / .avif
    shots/<name>.webp / .avif and shots/<name>-w640 or -w360

Requires Pillow, cwebp, avifenc, and pngquant.
"""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GAMES = ROOT / "assets" / "games"


def run(cmd: list[str]) -> None:
    subprocess.check_call(cmd)


def opaque_rgb(im: Image.Image) -> Image.Image:
    if im.mode == "RGBA":
        lo, hi = im.getchannel("A").getextrema()
        if lo == 255:
            return im.convert("RGB")
    if im.mode == "P":
        return im.convert("RGBA")
    return im


def save_png(im: Image.Image, path: Path) -> None:
    im.save(path, "PNG", optimize=True)


def quantize(path: Path) -> None:
    """Shrink fully opaque PNGs. Leave soft-edged alpha alone."""
    with Image.open(path) as im:
        if im.mode == "RGBA":
            hist = im.getchannel("A").histogram()
            if sum(hist[1:255]) > 0:
                return
    tmp = path.with_suffix(".pq.png")
    result = subprocess.run(
        [
            "pngquant",
            "--quality=75-92",
            "--speed",
            "1",
            "--force",
            "--skip-if-larger",
            "--output",
            str(tmp),
            str(path),
        ],
        check=False,
    )
    if result.returncode == 0 and tmp.exists() and tmp.stat().st_size < path.stat().st_size:
        tmp.replace(path)
    elif tmp.exists():
        tmp.unlink()


def encode(png: Path, webp: Path, avif: Path) -> None:
    run(["cwebp", "-q", "82", "-m", "6", "-metadata", "none", str(png), "-o", str(webp)])
    run(
        [
            "avifenc",
            "-q",
            "50",
            "-s",
            "6",
            "-y",
            "444",
            "-j",
            "all",
            "--ignore-exif",
            "--ignore-xmp",
            "--ignore-icc",
            str(png),
            str(avif),
        ]
    )


def resize_to(im: Image.Image, width: int) -> Image.Image:
    height = max(1, round(im.height * width / im.width))
    return im.resize((width, height), Image.Resampling.LANCZOS)


def extra_widths(path: Path, width: int) -> list[tuple[str, int]]:
    if path.name == "icon-512.png":
        return [("icon-256", 256)]
    if path.name == "feature-1024x500.png":
        return [("feature-w640", 640)]
    if path.parent.name == "shots":
        if width >= 1000:
            return [(f"{path.stem}-w640", 640)]
        if width >= 600:
            return [(f"{path.stem}-w360", 360)]
    return []


def optimize_png(path: Path) -> None:
    with Image.open(path) as raw:
        im = opaque_rgb(raw)
        if im.mode not in ("RGB", "RGBA"):
            im = im.convert("RGBA")
        save_png(im, path)
    quantize(path)
    with Image.open(path) as im:
        im = opaque_rgb(im)
        encode(path, path.with_suffix(".webp"), path.with_suffix(".avif"))
        for stem, width in extra_widths(path, im.width):
            if width >= im.width:
                continue
            resized = resize_to(im, width)
            with tempfile.TemporaryDirectory() as tmp:
                png = Path(tmp) / "resized.png"
                save_png(resized, png)
                encode(png, path.with_name(stem + ".webp"), path.with_name(stem + ".avif"))
    size = path.stat().st_size
    webp = path.with_suffix(".webp").stat().st_size
    avif = path.with_suffix(".avif").stat().st_size
    print(f"{path.relative_to(ROOT)}  png {size // 1024}KB  webp {webp // 1024}KB  avif {avif // 1024}KB")


def canonical_pngs() -> list[Path]:
    found: list[Path] = []
    if not GAMES.exists():
        return found
    for path in sorted(GAMES.rglob("*.png")):
        name = path.name
        if name in {"icon-512.png", "feature-1024x500.png", "title-logo.png"}:
            found.append(path)
        elif path.parent.name == "shots" and "-w" not in path.stem:
            found.append(path)
    return found


def main() -> None:
    pngs = canonical_pngs()
    if not pngs:
        raise SystemExit(f"No canonical PNGs under {GAMES}")
    for path in pngs:
        optimize_png(path)


if __name__ == "__main__":
    main()
