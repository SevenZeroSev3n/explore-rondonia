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


def castanheira_slices(seed: int = 7) -> list[Image.Image]:
    """Brazil-nut tree (castanheira): long straight trunk, wide flat crown. 24x24, 26 slices."""
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


SKIN = (196, 140, 100, 255)
SHIRT = (214, 92, 52, 255)
TROUSERS = (56, 70, 104, 255)
HAT = (222, 200, 140, 255)
IRON = (40, 40, 46, 255)
IRON_LIGHT = (70, 70, 78, 255)
TRIM = (150, 40, 34, 255)
BRICK = (170, 104, 70, 255)
BRICK_DARK = (136, 80, 56, 255)
ROOF = (128, 132, 136, 255)
ROOF_DARK = (104, 108, 112, 255)
TANK = (176, 182, 186, 255)
TANK_DARK = (140, 146, 150, 255)


def disc(img: Image.Image, cx: float, cy: float, r: float, color: RGBA) -> None:
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if math.hypot(x - cx, y - cy) <= r:
                img.putpixel((x, y), color)


def traveler_slices() -> list[Image.Image]:
    """The on-foot traveler for dioramas, 8x8 px, 14 slices. Faces up."""
    out = []
    for z in range(14):
        s = blank(8, 8)
        if z <= 4:                       # legs
            rect(s, 2, 3, 3, 4, TROUSERS)
            rect(s, 4, 3, 5, 4, TROUSERS)
        elif z <= 9:                     # torso and arms
            rect(s, 1, 3, 6, 4, SHIRT)
            if z >= 8:
                s.putpixel((1, 2), SKIN)
                s.putpixel((6, 2), SKIN)
        elif z <= 11:                    # head
            rect(s, 2, 2, 5, 5, SKIN)
            rect(s, 3, 1, 4, 1, SKIN)    # nose: shows the facing
        else:                            # hat
            rect(s, 1 if z == 12 else 2, 1 if z == 12 else 2, 6 if z == 12 else 5, 6 if z == 12 else 5, HAT)
        out.append(s)
    return out


def locomotive_slices() -> list[Image.Image]:
    """A small steam locomotive, 18x40 px, 17 slices; boiler at the front (top), open cab at the back."""
    w, h = 18, 40
    out = []
    for z in range(17):
        s = blank(w, h)
        if z <= 3:                                   # wheels along both sides
            for y0 in (6, 14, 22, 31):
                rect(s, 1, y0, 2, y0 + 4, IRON)
                rect(s, 15, y0, 16, y0 + 4, IRON)
        if z == 3:
            rect(s, 3, 3, 14, 37, IRON_LIGHT)          # frame
        if z == 4:
            rect(s, 2, 2, 15, 38, IRON)
            rect(s, 4, 0, 13, 1, TRIM)                 # cowcatcher
        if 5 <= z <= 11:                               # boiler: round cross-section
            half = int(round(math.sqrt(max(0.0, 16 - (z - 8) ** 2)) * 1.4))
            rect(s, 8 - half, 3, 9 + half, 25, IRON)
            if z == 8:
                rect(s, 8 - half, 3, 9 + half, 3, TRIM)
        if 12 <= z <= 15:                              # smokestack
            rect(s, 7, 5, 10, 8, IRON_LIGHT if z == 15 else IRON)
        if 5 <= z <= 14:                               # cab walls, hollow inside
            outline(s, 3, 27, 14, 38, TRIM if z == 5 else IRON)
            if 10 <= z <= 12:
                rect(s, 3, 30, 3, 34, CLEAR)           # side windows
                rect(s, 14, 30, 14, 34, CLEAR)
        if z == 15 or z == 16:
            rect(s, 2, 26, 15, 39, ROOF_DARK if z == 15 else IRON_LIGHT)
        out.append(s)
    return out


def shed_slices() -> list[Image.Image]:
    """A railway shed (galpão), 64x36 px, 20 slices, gabled roof along its length."""
    w, h = 64, 36
    out = []
    for z in range(20):
        s = blank(w, h)
        if z <= 12:
            outline(s, 1, 1, 62, 34, BRICK if z % 4 else BRICK_DARK)
            if z <= 8:
                rect(s, 26, 1, 37, 1, CLEAR)           # big door on the front side (top = front)
            if 5 <= z <= 8:
                for x0 in (6, 16, 46, 56):
                    rect(s, x0, 34, x0 + 2, 34, CLEAR)  # windows
                    rect(s, x0, 1, x0 + 2, 1, CLEAR)
        else:
            inset = (z - 13) * 2 + 0                   # gable: narrows towards the ridge
            if inset <= 16:
                rect(s, 0, inset, 63, 35 - inset, ROOF if z % 2 else ROOF_DARK)
        out.append(s)
    return out


def water_tower_slices() -> list[Image.Image]:
    """One of the Três Caixas d'Água: tank on four legs, 16x16 px, 36 slices."""
    w = h = 16
    out = []
    for z in range(36):
        s = blank(w, h)
        if z <= 22:
            spread = 1 + (22 - z) // 8                 # legs lean out at the bottom
            for x0, y0 in ((2, 2), (12, 2), (2, 12), (12, 12)):
                x = x0 - spread + 1 if x0 < 8 else x0 + spread - 1
                y = y0 - spread + 1 if y0 < 8 else y0 + spread - 1
                rect(s, max(0, x), max(0, y), min(15, x + 1), min(15, y + 1), IRON_LIGHT)
            if z in (8, 16):
                outline(s, 3, 3, 12, 12, IRON_LIGHT)   # bracing rings
        if 23 <= z <= 31:
            disc(s, 7.5, 7.5, 7.0, TANK if z % 3 else TANK_DARK)
        if z >= 32:
            disc(s, 7.5, 7.5, 6.5 - (z - 32) * 2.0, TANK_DARK)
        out.append(s)
    return out


BARK_LIGHT = (150, 140, 124, 255)
BARK_PALE = (214, 208, 192, 255)
PALM = [(58, 98, 52, 255), (78, 122, 60, 255), (104, 146, 70, 255)]
IPE = [(201, 154, 30, 255), (232, 195, 58, 255), (242, 214, 90, 255)]
EMBAUBA = [(111, 143, 116, 255), (159, 184, 160, 255)]
SHRUB = [(40, 78, 44, 255), (56, 98, 52, 255), (72, 116, 58, 255)]


def _trunk(s: Image.Image, cx: int, cy: int, size: int, color: RGBA) -> None:
    rect(s, cx, cy, cx + size - 1, cy + size - 1, color)


def _blob(s: Image.Image, cx: float, cy: float, r: float, colors, rng: random.Random, t: float) -> None:
    """Rough disc: leafy noise on the edge, lighter towards the top (t = 0 bottom .. 1 top)."""
    w, h = s.size
    for y in range(h):
        for x in range(w):
            if math.hypot(x - cx, y - cy) <= r - rng.random() * 1.2:
                shade = min(len(colors) - 1, int(t * len(colors) + rng.random() * 1.2))
                s.putpixel((x, y), colors[shade])


def seringueira_slices(seed: int = 11) -> list[Image.Image]:
    """Rubber tree (seringueira): pale trunk, dense rounded crown. 20x20, 20 slices."""
    rng = random.Random(seed)
    out = []
    for z in range(20):
        s = blank(20, 20)
        if z <= 9:
            _trunk(s, 9, 9, 2, BARK_LIGHT)
        if z >= 6:
            t = (z - 6) / 13
            _blob(s, 9.5, 9.5, 9.0 * math.sqrt(max(0.0, 1 - (2 * t - 0.9) ** 2)), LEAF, rng, t)
        out.append(s)
    return out


def acai_slices(seed: int = 13) -> list[Image.Image]:
    """Açaí palm: very slender trunk, a small crown of drooping feather fronds. 12x12, 24 slices."""
    out = []
    for z in range(24):
        s = blank(12, 12)
        if z <= 19:
            s.putpixel((5, 5), (120, 124, 104, 255))
        if z >= 17:
            reach = {17: 5, 18: 5, 19: 5, 20: 4, 21: 3, 22: 2, 23: 1}[z]
            inner = 3 if z <= 18 else 0          # lower fronds droop: only their tips this low
            for k in range(8):
                a = k * math.pi / 4 + 0.2
                for r in range(inner, reach + 1):
                    x, y = int(round(5.5 + math.cos(a) * r)), int(round(5.5 + math.sin(a) * r))
                    if 0 <= x < 12 and 0 <= y < 12:
                        s.putpixel((x, y), PALM[min(2, (z - 17) // 2)])
        out.append(s)
    return out


def buriti_slices(seed: int = 17) -> list[Image.Image]:
    """Buriti palm: thick trunk, round crown of fan leaves. 18x18, 24 slices."""
    out = []
    for z in range(24):
        s = blank(18, 18)
        if z <= 16:
            _trunk(s, 8, 8, 2, (112, 96, 76, 255))
        if z >= 15:
            t = (z - 15) / 8
            r = 8.0 * math.sqrt(max(0.0, 1 - (2 * t - 0.7) ** 2))
            for y in range(18):
                for x in range(18):
                    d = math.hypot(x - 8.5, y - 8.5)
                    a = math.atan2(y - 8.5, x - 8.5)
                    if d <= r and (math.sin(a * 9) > -0.3 or d < r * 0.5):   # fan-leaf points
                        s.putpixel((x, y), PALM[min(2, int(t * 3))])
        out.append(s)
    return out


def ipe_slices(seed: int = 19) -> list[Image.Image]:
    """Yellow ipê in bloom (dry season): dark trunk, airy crown of yellow flowers. 20x20, 20 slices."""
    rng = random.Random(seed)
    out = []
    for z in range(20):
        s = blank(20, 20)
        if z <= 10:
            _trunk(s, 9, 9, 2, TRUNK_DARK)
        if z >= 8:
            t = (z - 8) / 11
            r = 8.5 * math.sqrt(max(0.0, 1 - (2 * t - 0.8) ** 2))
            for y in range(20):
                for x in range(20):
                    if math.hypot(x - 9.5, y - 9.5) <= r and rng.random() < 0.7:   # airy, leafless
                        s.putpixel((x, y), IPE[min(2, int(t * 3 + rng.random()))])
        out.append(s)
    return out


def embauba_slices(seed: int = 23) -> list[Image.Image]:
    """Embaúba (Cecropia): thin pale trunk, candelabra branches, flat umbrella of big silvery leaves.
    16x16, 18 slices."""
    rng = random.Random(seed)
    tips = [(3, 4), (12, 3), (4, 12), (12, 12), (8, 7)]
    out = []
    for z in range(18):
        s = blank(16, 16)
        if z <= 12:
            s.putpixel((7, 7), BARK_PALE)
        if 10 <= z <= 13:                        # branches climbing out to the tips
            f = (z - 10) / 3
            for tx, ty in tips:
                s.putpixel((int(7 + (tx - 7) * f), int(7 + (ty - 7) * f)), BARK_PALE)
        if z >= 14:
            for tx, ty in tips:
                _blob(s, tx, ty, 3.0 - (z - 14) * 0.6, EMBAUBA, rng, (z - 14) / 3)
        out.append(s)
    return out


def shrub_slices(seed: int = 29) -> list[Image.Image]:
    """Undergrowth bush. 10x10, 6 slices."""
    rng = random.Random(seed)
    out = []
    for z in range(6):
        s = blank(10, 10)
        t = z / 5
        _blob(s, 4.5, 4.5, 4.5 * math.sqrt(max(0.0, 1 - t * t * 0.9)), SHRUB, rng, t)
        out.append(s)
    return out


def to_sheet(slices: list[Image.Image]) -> Image.Image:
    w, h = slices[0].size
    sheet = Image.new("RGBA", (w * len(slices), h), CLEAR)
    for i, s in enumerate(slices):
        if s.size != (w, h):
            raise ValueError(f"slice {i} is {s.size}, expected {(w, h)}")
        sheet.paste(s, (i * w, 0))
    return sheet


STACKS = {
    "truck": pickup_slices,
    "castanheira": castanheira_slices,
    "seringueira": seringueira_slices,
    "acai": acai_slices,
    "buriti": buriti_slices,
    "ipe": ipe_slices,
    "embauba": embauba_slices,
    "shrub": shrub_slices,
    "traveler": traveler_slices,
    "locomotive": locomotive_slices,
    "shed": shed_slices,
    "water_tower": water_tower_slices,
}


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
