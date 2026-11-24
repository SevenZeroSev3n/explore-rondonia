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
    "truck": (27, 48, 12, 16),
    "castanheira": (32, 32, 35, 12),
    "seringueira": (27, 27, 27, 12),
    "acai": (16, 16, 32, 8),
    "buriti": (24, 24, 32, 8),
    "ipe": (27, 27, 27, 8),
    "embauba": (21, 21, 24, 8),
    "shrub": (13, 13, 8, 6),
    "traveler": (11, 11, 19, 8),
    "locomotive": (24, 53, 23, 12),
    "shed": (85, 48, 27, 12),
    "water_tower": (21, 21, 48, 8),
}

# Per-stack carving options for four-view sheets (views_to_slices.silhouette):
# a lower tolerance for light objects on a flat light background (the white truck); a lower
# cover for objects whose thin parts (trunks) would otherwise vanish.
VIEW_OPTIONS = {
    "truck": {"tolerance": 12},
    "embauba": {"cover": 0.2},
    "acai": {"cover": 0.2},
}


def fit(slices: list[Image.Image], W: int, L: int, H: int) -> list[Image.Image]:
    """Nearest-neighbour resample of a code-drawn placeholder to the contract size (W x L, H slices).

    Placeholders are drawn at fixed sizes; this keeps them usable as a fallback when the
    contract changes (ADR 0005 resolution update). Real art never goes through here.
    """
    n = len(slices)
    picked = [slices[min(n - 1, z * n // H)] for z in range(H)]
    return [s.resize((W, L), Image.Resampling.NEAREST) for s in picked]


def build(name: str) -> str:
    W, L, H, colours = STACKS[name]
    model = VOX / f"{name}.vox"
    src = VIEWS / f"{name}_views.png"
    if model.exists():
        slices = vox.to_slices(vox.read(model))
        how = f"from {model.relative_to(ROOT)}"
    elif src.exists():
        views = v2s.quadrants(Image.open(src).convert("RGBA"))
        filled, colour = v2s.carve(views, W, L, H, **VIEW_OPTIONS.get(name, {}))
        slices = v2s.to_slices(filled, colour, colours)
        how = f"from {src.relative_to(ROOT)}"
    else:
        slices = fit(placeholder.STACKS[name](), W, L, H)
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
