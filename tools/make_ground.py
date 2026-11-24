"""Draw the layer-1 ground art in code (ADR 0009): a tiling pasture texture and an atlas of
small flat decals (grass tufts, flowers, stones, dry grass).

Writes:
  game/assets/ground/pasture_tile.png   TILE x TILE, tiles seamlessly
  game/assets/ground/decals.png         one row of CELL x CELL cells, see DECALS

Deterministic (fixed seeds), so rerunning gives the same files.

Usage:
  python3 tools/make_ground.py
"""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "game/assets/ground"
TILE = 128
CELL = 8

# Pasture greens from the ADR 0005 palette direction; BASE matches state_map.gd PASTURE.
BASE = (78, 122, 64, 255)
DARK = (66, 106, 54, 255)
DARKER = (56, 92, 48, 255)
LIGHT = (92, 138, 72, 255)
DRY = (138, 140, 82, 255)
STRAW = (176, 162, 96, 255)
LEAF = [(46, 88, 42, 255), (84, 140, 64, 255), (122, 172, 86, 255)]
STONE = [(128, 124, 116, 255), (156, 150, 140, 255), (104, 100, 94, 255)]
YELLOW = (236, 204, 74, 255)
WHITE = (236, 232, 220, 255)
PINK = (214, 120, 150, 255)
CLEAR = (0, 0, 0, 0)

# Decal names in atlas order; the game reads them by index (state_map.gd DECALS).
DECALS = ["tuft_a", "tuft_b", "tuft_c", "dry_tuft", "flowers_yellow", "flowers_white",
          "flowers_pink", "stone_small", "stone_pair", "leaf_litter"]


def pasture_tile() -> Image.Image:
    """Speckled grass, darker patches and short blades; wraps at the edges."""
    rng = random.Random(9009)
    img = Image.new("RGBA", (TILE, TILE), BASE)
    px = img.load()
    for _ in range(14):                                 # soft darker patches, irregular
        cx, cy, r = rng.randrange(TILE), rng.randrange(TILE), rng.randint(4, 12)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r and rng.random() < 0.3 * (1 - (dx * dx + dy * dy) / (r * r + 1)) + 0.1:
                    px[(cx + dx) % TILE, (cy + dy) % TILE] = DARK
    for _ in range(TILE * TILE // 9):                   # speckles
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        px[x, y] = rng.choice([DARK, DARKER, LIGHT, LIGHT, DRY])
    for _ in range(TILE * 2):                           # short vertical blades (2 px)
        x, y = rng.randrange(TILE), rng.randrange(TILE)
        c = rng.choice([LIGHT, DARKER, LIGHT])
        px[x, y] = c
        px[x, (y + 1) % TILE] = c
    return img


def _put(img: Image.Image, pts: list[tuple[int, int]], colour) -> None:
    for x, y in pts:
        if 0 <= x < CELL and 0 <= y < CELL:
            img.putpixel((x, y), colour)


def decal(name: str) -> Image.Image:
    img = Image.new("RGBA", (CELL, CELL), CLEAR)
    rng = random.Random(name)
    if name.startswith("tuft") or name == "dry_tuft":
        cols = [STRAW, DRY, STRAW] if name == "dry_tuft" else LEAF
        blades = {"tuft_a": [1, 3, 4, 6], "tuft_b": [2, 3, 5], "tuft_c": [0, 2, 4, 5, 7],
                  "dry_tuft": [1, 2, 4, 6]}[name]
        for x in blades:                                # blades fanning up from the base row
            h = rng.randint(3, 6)
            lean = (x - 3.5) / 4
            for i in range(h):
                _put(img, [(round(x + lean * i * 0.5), CELL - 1 - i)], cols[min(i // 2, 2)])
    elif name.startswith("flowers"):
        petal = {"flowers_yellow": YELLOW, "flowers_white": WHITE, "flowers_pink": PINK}[name]
        for x, y in [(1, 4), (4, 2), (6, 5)]:
            _put(img, [(x, y + 1), (x, y + 2)], LEAF[0])          # stems
            _put(img, [(x, y), (x - 1, y), (x + 1, y), (x, y - 1)], petal)
    elif name.startswith("stone"):
        spots = [(3, 5, 2)] if name == "stone_small" else [(2, 5, 2), (5, 3, 1)]
        for cx, cy, r in spots:
            for y in range(cy - r, cy + r):
                for x in range(cx - r, cx + r + 1):
                    if (x - cx) ** 2 + (y - cy + 0.5) ** 2 <= r * r + 0.5:
                        _put(img, [(x, y)], STONE[0])
            _put(img, [(cx - 1, cy - r)], STONE[1])               # highlight
            _put(img, [(cx + r - 1, cy + r - 1)], STONE[2])       # shade
    elif name == "leaf_litter":
        for _ in range(9):
            _put(img, [(rng.randrange(CELL), rng.randrange(CELL))], rng.choice([STRAW, DRY, (122, 92, 58, 255)]))
    else:
        raise ValueError(name)
    return img


def decal_atlas() -> Image.Image:
    atlas = Image.new("RGBA", (CELL * len(DECALS), CELL), CLEAR)
    for i, name in enumerate(DECALS):
        atlas.paste(decal(name), (i * CELL, 0))
    return atlas


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    pasture_tile().save(OUT / "pasture_tile.png")
    decal_atlas().save(OUT / "decals.png")
    print(f"wrote {OUT / 'pasture_tile.png'} and {OUT / 'decals.png'} ({len(DECALS)} decals)")


if __name__ == "__main__":
    main()
