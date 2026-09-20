#!/usr/bin/env python3
"""Compose iPhone Duo product renders from the simulator captures.

    python3 scripts/make-duo-render.py            (needs Pillow: pip install pillow)

Folded render  -> docs/brand/duo-folded.png   from docs/screenshots/duo/closed-session.png
Open render    -> docs/brand/duo-open.png     from docs/screenshots/duo/home.png

The open render is skipped while the inner-display capture is still blank, so rerun this
after `scripts/capture-screens.sh` has produced a real docs/screenshots/duo/home.png.
Both renders are transparent PNGs: the site and the portfolio page put their own
background behind them.
"""
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageStat
except ModuleNotFoundError:
    sys.exit("Pillow is not installed. Either run\n"
             "    python3 -m pip install --user --break-system-packages pillow\n"
             "or just commit and push docs/screenshots/duo and let CI build the render.")

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / "docs" / "screenshots" / "duo"
OUT = ROOT / "docs" / "brand"

BODY = (38, 38, 46)        # titanium casing
RIM = (168, 170, 182)      # machined edge catching the light
SPINE = (58, 59, 70)       # the folded half behind, lit from the same side
SHADOW = (0, 0, 0, 170)
GLOW = (250, 209, 89)      # brand yellow, behind the device


def is_blank(path: Path) -> bool:
    return ImageStat.Stat(Image.open(path).convert("L")).mean[0] <= 6


def rounded(size, radius, fill):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=fill)
    return img


def device(shot: Image.Image, screen_w: int, bezel: int, radius: int, spine: bool) -> Image.Image:
    """One device: casing, screen inset, and for the folded pose a hint of the half behind."""
    scale = screen_w / shot.width
    sw, sh = screen_w, int(shot.height * scale)
    bw, bh = sw + bezel * 2, sh + bezel * 2
    spine_w = int(bw * 0.055) if spine else 0

    pad = 130
    canvas = Image.new("RGBA", (bw + spine_w + pad * 2, bh + pad * 2), (0, 0, 0, 0))
    x0, y0 = pad + spine_w, pad

    # Warm glow behind the device so it lifts off a dark page.
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse(
        [x0 - spine_w - 60, y0 + bh * 0.12, x0 + bw + 60, y0 + bh * 1.02], fill=GLOW + (46,))
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(90)))

    # Drop shadow under the whole device.
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x0 - spine_w + 12, y0 + 34, x0 + bw + 12, y0 + bh + 34], radius=radius, fill=SHADOW)
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(40)))

    # The folded half sitting behind, so the phone reads as closed rather than as a slab.
    if spine:
        back = rounded((bw, bh), radius, SPINE)
        canvas.alpha_composite(back, (x0 - spine_w, y0 + 10))
        # Crease where the two halves meet.
        crease = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ImageDraw.Draw(crease).rounded_rectangle(
            [x0 - spine_w + 4, y0 + 10, x0 - spine_w + int(spine_w * 0.55), y0 + bh + 10],
            radius=int(spine_w * 0.4), fill=(112, 114, 126, 220))
        canvas.alpha_composite(crease.filter(ImageFilter.GaussianBlur(2)))

    # Casing: a bright machined rim, then the darker body just inside it.
    canvas.alpha_composite(rounded((bw, bh), radius, RIM), (x0, y0))
    canvas.alpha_composite(rounded((bw - 6, bh - 6), radius - 3, BODY), (x0 + 3, y0 + 3))

    # Screen.
    screen = shot.convert("RGB").resize((sw, sh), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=max(radius - bezel, 8), fill=255)
    canvas.paste(screen, (x0 + bezel, y0 + bezel), mask)

    # A soft diagonal sheen across the glass.
    sheen = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sheen).polygon(
        [(x0, y0 + int(bh * 0.10)), (x0 + bw, y0 - int(bh * 0.16)),
         (x0 + bw, y0 + int(bh * 0.08)), (x0, y0 + int(bh * 0.34))], fill=(255, 255, 255, 16))
    clip = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(clip).rounded_rectangle([x0, y0, x0 + bw, y0 + bh], radius=radius, fill=255)
    sheen.putalpha(Image.composite(sheen.getchannel("A"), Image.new("L", canvas.size, 0), clip))
    canvas.alpha_composite(sheen.filter(ImageFilter.GaussianBlur(14)))
    return canvas


def build(name: str, source: Path, spine: bool, screen_w: int):
    if not source.exists():
        print(f"skip {name}: {source.relative_to(ROOT)} is missing")
        return
    if is_blank(source):
        print(f"skip {name}: {source.relative_to(ROOT)} is still blank, rerun scripts/capture-screens.sh")
        return
    shot = Image.open(source)
    img = device(shot, screen_w=screen_w, bezel=int(screen_w * 0.022), radius=int(screen_w * 0.10), spine=spine)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name, optimize=True)
    print(f"wrote docs/brand/{name}  {img.size[0]}x{img.size[1]}")


if __name__ == "__main__":
    build("duo-folded.png", SHOTS / "closed-session.png", spine=True, screen_w=760)
    build("duo-open.png", SHOTS / "home.png", spine=False, screen_w=1100)
