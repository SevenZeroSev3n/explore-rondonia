"""Build every game slice sheet (ADR 0004).

For each stack in STACKS, the first source that exists wins:
  1. art/vox/<name>.vox — a MagicaVoxel model (front toward +Y, see tools/vox.py), sliced as is;
  2. art/views/<name>_views.png — a 2x2 four-view sheet from any image generator
     (see art/views/00-workflow.md), carved with views_to_slices;
  3. the code-drawn placeholder from make_placeholder_stacks. Sizes and slice counts are the contract
with the game (scenes and scripts hard-code the slice counts), so both routes use the same ones.

Usage:
  python3 tools/build_stacks.py [--only NAME ...]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_placeholder_stacks as placeholder  # noqa: E402
import views_to_slices as v2s  # noqa: E402
import vox  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
VOX = ROOT / "art/vox"
VIEWS = ROOT / "art/views"
OUT = ROOT / "game/assets/stacks"

# name: (W, L, H, palette colours). L is the length along the facing direction.
STACKS = {
    "truck": (20, 36, 9, 16),
    "castanheira": (24, 24, 26, 12),
    "seringueira": (20, 20, 20, 12),
    "acai": (12, 12, 24, 8),
    "buriti": (18, 18, 24, 8),
    "ipe": (20, 20, 20, 8),
    "embauba": (16, 16, 18, 8),
    "shrub": (10, 10, 6, 6),
    "traveler": (8, 8, 14, 8),
    "locomotive": (18, 40, 17, 12),
    "shed": (64, 36, 20, 12),
    "water_tower": (16, 16, 36, 8),
}


def build(name: str) -> str:
    W, L, H, colours = STACKS[name]
    model = VOX / f"{name}.vox"
    src = VIEWS / f"{name}_views.png"
    if model.exists():
        slices = vox.to_slices(vox.read(model))
        how = f"from {model.relative_to(ROOT)}"
    elif src.exists():
        filled, colour = v2s.carve(v2s.quadrants(Image.open(src).convert("RGBA")), W, L, H)
        slices = v2s.to_slices(filled, colour, colours)
        how = f"from {src.relative_to(ROOT)}"
    else:
        slices = placeholder.STACKS[name]()
        how = "placeholder"
    got = (slices[0].size, len(slices))
    if got != ((W, L), H):
        raise SystemExit(f"{name}: built {got}, contract is {((W, L), H)}")
    dst = OUT / name / f"{name}_slices.png"
    dst.parent.mkdir(parents=True, exist_ok=True)
    placeholder.to_sheet(slices).save(dst)
    return f"{name}: {H} slices of {W}x{L}px ({how})"


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--only", nargs="*", choices=sorted(STACKS))
    for name in p.parse_args().only or STACKS:
        print(build(name))


if __name__ == "__main__":
    main()
