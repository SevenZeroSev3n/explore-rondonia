"""Render a slice sheet the way the game's SpriteStack draws it, at several angles (review aid).

Each slice is turned by the angle (clockwise, like SpriteStack.angle), squashed vertically and
lifted one pixel per slice; the result is scaled up with nearest-neighbour. Under the turntable,
the raw slices are laid out ground first.

Usage:
  python3 tools/preview_stack.py SHEET.png --count N OUT.png [--squash 0.75] [--scale 4]
"""
from __future__ import annotations

import argparse

from PIL import Image

ANGLES = (0, 45, 90, 135, 180, 225, 270, 315)
BG = (196, 186, 160, 255)


def render(slices: list[Image.Image], angle_deg: float, squash: float) -> Image.Image:
    w, h = slices[0].size
    side = int((w * w + h * h) ** 0.5) + 2
    canvas = Image.new("RGBA", (side, side + len(slices)), (0, 0, 0, 0))
    for z, s in enumerate(slices):
        turned = s.rotate(-angle_deg, resample=Image.Resampling.NEAREST, expand=True)
        tw, th = turned.size
        sh = max(1, round(th * squash))
        turned = turned.resize((tw, sh), Image.Resampling.NEAREST)
        x = (side - tw) // 2
        y = len(slices) + (side - sh) // 2 - z
        canvas.alpha_composite(turned, (x, y))
    return canvas


def preview(sheet: Image.Image, count: int, squash: float = 0.75, scale: int = 4) -> Image.Image:
    w, h = sheet.width // count, sheet.height
    slices = [sheet.crop((i * w, 0, (i + 1) * w, h)).convert("RGBA") for i in range(count)]
    views = [render(slices, a, squash) for a in ANGLES]
    vw, vh = views[0].size
    strip_h = h + 2
    out = Image.new("RGBA", (max(vw * len(views), (w + 1) * count), vh + strip_h), BG)
    for i, v in enumerate(views):
        out.alpha_composite(v, (i * vw, 0))
    for i, s in enumerate(slices):
        out.alpha_composite(s, (i * (w + 1), vh + 1))
    return out.resize((out.width * scale, out.height * scale), Image.Resampling.NEAREST)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("sheet")
    p.add_argument("out")
    p.add_argument("--count", type=int, required=True)
    p.add_argument("--squash", type=float, default=0.75)
    p.add_argument("--scale", type=int, default=4)
    a = p.parse_args()
    preview(Image.open(a.sheet), a.count, a.squash, a.scale).save(a.out)
    print(f"wrote {a.out}")


if __name__ == "__main__":
    main()
