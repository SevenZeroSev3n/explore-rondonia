"""Generate placeholder slice sheets until the AI 4-view art exists (ADR 0004).

Writes one-row sheets (ground slice on the left, art facing up / -Y) into
game/assets/stacks/<name>/<name>_slices.png.

Usage:
  python3 tools/make_placeholder_stacks.py [--out game/assets/stacks]
"""
from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image

RGBA = tuple[int, int, int, int]
CLEAR: RGBA = (0, 0, 0, 0)

# Draft colours from the ADR 0005 palette direction (greens, red dirt, river blue).
TYRE = (34, 32, 36, 255)
CHASSIS = (58, 54, 60, 255)
BODY = (226, 222, 208, 255)
BODY_SHADE = (184, 178, 164, 255)
BED_FLOOR = (120, 112, 100, 255)
GLASS = (78, 112, 132, 255)
BUMPER = (96, 96, 104, 255)
HEADLIGHT = (250, 236, 170, 255)
TAILLIGHT = (196, 48, 40, 255)
TRUNK = (102, 70, 46, 255)
TRUNK_DARK = (78, 52, 36, 255)
LEAF = [(46, 92, 52, 255), (58, 112, 60, 255), (76, 134, 68, 255), (98, 156, 78, 255)]


def blank(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), CLEAR)


def rect(img: Image.Image, x0: int, y0: int, x1: int, y1: int, color: RGBA) -> None:
    """Fill the inclusive rectangle [x0..x1] x [y0..y1]."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            img.putpixel((x, y), color)


def outline(img: Image.Image, x0: int, y0: int, x1: int, y1: int, color: RGBA) -> None:
    for x in range(x0, x1 + 1):
        img.putpixel((x, y0), color)
        img.putpixel((x, y1), color)
    for y in range(y0, y1 + 1):
        img.putpixel((x0, y), color)
        img.putpixel((x1, y), color)


def pickup_slices() -> list[Image.Image]:
    """A generic pickup truck, 20x36 px footprint, 9 slices. Front (hood) at the top."""
    w, h = 20, 36
    slices = []

    # z0-1: tyres at the four corners + chassis
    for z in range(2):
        s = blank(w, h)
        if z == 1:
            rect(s, 4, 4, 15, 31, CHASSIS)
        for x0 in (1, 16):
            for y0 in (5, 24):
                rect(s, x0, y0, x0 + 2, y0 + 6, TYRE)
        slices.append(s)

    # z2-4: lower body, bumpers and lights
    for z in range(2, 5):
        s = blank(w, h)
        rect(s, 2, 2, 17, 33, BODY if z < 4 else BODY_SHADE)
        if z == 2:
            rect(s, 3, 1, 16, 1, BUMPER)
            rect(s, 3, 34, 16, 34, BUMPER)
        if z == 3:
            rect(s, 3, 2, 4, 2, HEADLIGHT)
            rect(s, 15, 2, 16, 2, HEADLIGHT)
            rect(s, 2, 33, 3, 33, TAILLIGHT)
            rect(s, 16, 33, 17, 33, TAILLIGHT)
        if z == 4:
            rect(s, 4, 18, 15, 31, BED_FLOOR)  # open bed: floor visible from above
        slices.append(s)

    # z5: hood top + cab + bed walls (hollow bed — something 4-view art cannot do)
    s = blank(w, h)
    rect(s, 3, 2, 16, 8, BODY)
    rect(s, 2, 9, 17, 16, BODY)
    outline(s, 2, 17, 17, 33, BODY)
    slices.append(s)

    # z6-7: cab with windows, bed walls continue on z6
    for z in (6, 7):
        s = blank(w, h)
        rect(s, 3, 9, 16, 16, BODY)
        rect(s, 4, 9, 15, 10, GLASS)   # windscreen
        rect(s, 4, 15, 15, 16, GLASS)  # rear window
        rect(s, 3, 11, 3, 14, GLASS)   # side windows
        rect(s, 16, 11, 16, 14, GLASS)
        if z == 6:
            outline(s, 2, 17, 17, 33, BODY_SHADE)
        slices.append(s)

    # z8: roof
    s = blank(w, h)
    rect(s, 4, 10, 15, 15, BODY)
    slices.append(s)
    return slices


def tree_slices(seed: int = 7) -> list[Image.Image]:
    """A tall Amazonian tree (castanheira-like): long trunk, wide flat crown. 24x24, 26 slices."""
    w = h = 24
    cx = cy = (w - 1) / 2
    rng = random.Random(seed)
    trunk_top = 13
    crown_z0, crown_z1 = 12, 25
    slices = []
    for z in range(crown_z1 + 1):
        s = blank(w, h)
        if z <= trunk_top:
            rect(s, 10, 10, 12, 12, TRUNK)
            s.putpixel((10, 12), TRUNK_DARK)
            s.putpixel((11, 12), TRUNK_DARK)
        if z >= crown_z0:
            t = (z - crown_z0) / (crown_z1 - crown_z0)       # 0 bottom .. 1 top
            radius = 11.0 * math.sqrt(max(0.0, 1.0 - (2 * t - 0.6) ** 2 / 1.96))
            for y in range(h):
                for x in range(w):
                    d = math.hypot(x - cx, y - cy)
                    if d <= radius - rng.random() * 1.2:
                        shade = min(len(LEAF) - 1, int(t * len(LEAF) + rng.random() * 1.5))
                        s.putpixel((x, y), LEAF[shade])
        slices.append(s)
    return slices


def to_sheet(slices: list[Image.Image]) -> Image.Image:
    w, h = slices[0].size
    sheet = Image.new("RGBA", (w * len(slices), h), CLEAR)
    for i, s in enumerate(slices):
        if s.size != (w, h):
            raise ValueError(f"slice {i} is {s.size}, expected {(w, h)}")
        sheet.paste(s, (i * w, 0))
    return sheet


STACKS = {"truck": pickup_slices, "tree": tree_slices}


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--out", default=str(Path(__file__).resolve().parent.parent / "game/assets/stacks"))
    out = Path(p.parse_args().out)
    for name, build in STACKS.items():
        slices = build()
        dst = out / name / f"{name}_slices.png"
        dst.parent.mkdir(parents=True, exist_ok=True)
        to_sheet(slices).save(dst)
        w, h = slices[0].size
        print(f"wrote {dst}: {len(slices)} slices of {w}x{h}px")


if __name__ == "__main__":
    main()
