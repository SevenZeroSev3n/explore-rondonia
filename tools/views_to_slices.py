"""Turn a 4-view drawing into a slice sheet (ADR 0004): visual-hull voxel carving.

Input: one image laid out 2x2 on a flat background (any generator, any size):

    +-----------+-----------+
    | TOP       | SIDE      |   TOP:   seen from above, front pointing UP
    | (from     | (right    |   SIDE:  seen from its right side, front pointing LEFT
    |  above)   |  side)    |   FRONT: seen from the front
    +-----------+-----------+   BACK:  seen from behind
    | FRONT     | BACK      |
    +-----------+-----------+

Each view is cropped to its object, resized to the target box (W wide, L long, H tall) and
used as a silhouette. A voxel is kept when every silhouette that sees it says "object".
Colours come from the view that faces each exposed voxel. 4 views cannot express holes or
overhangs (ADR 0004): those need a MagicaVoxel model instead.

Output: one row of H slices of W x L px, ground on the left, art facing up (-Y).

Usage:
  python3 tools/views_to_slices.py IN.png OUT.png --size W L H [--colors 16] [--bg-tolerance 40]
"""
from __future__ import annotations

import argparse

import numpy as np
from PIL import Image


def quadrants(img: Image.Image) -> dict[str, Image.Image]:
    w, h = img.size
    hw, hh = w // 2, h // 2
    return {
        "top": img.crop((0, 0, hw, hh)),
        "side": img.crop((hw, 0, w, hh)),
        "front": img.crop((0, hh, hw, h)),
        "back": img.crop((hw, hh, w, h)),
    }


def background_mask(rgba: np.ndarray, tolerance: float) -> np.ndarray:
    """True where the pixel is background: transparent, or close to the corners' colour."""
    rgb = rgba[..., :3].astype(np.float32)
    corners = np.array([rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]])
    bg = np.median(corners, axis=0)
    close = np.linalg.norm(rgb - bg, axis=-1) <= tolerance
    return close | (rgba[..., 3] < 128)


def silhouette(view: Image.Image, size: tuple[int, int], tolerance: float) -> tuple[np.ndarray, np.ndarray]:
    """Crop the view to its object and resize to size (w, h): (mask[h, w] bool, rgb[h, w, 3])."""
    rgba = np.asarray(view.convert("RGBA"))
    fg = ~background_mask(rgba, tolerance)
    ys, xs = np.nonzero(fg)
    if len(xs) == 0:
        raise ValueError("a view has no object in it (check the background tolerance)")
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    cropped = Image.fromarray(rgba).crop(box)
    mask_img = Image.fromarray((fg[box[1]:box[3], box[0]:box[2]] * 255).astype(np.uint8))
    mask = np.asarray(mask_img.resize(size, Image.Resampling.BOX)) >= 128
    rgb = np.asarray(cropped.convert("RGB").resize(size, Image.Resampling.BOX))
    return mask, rgb


def carve(views: dict[str, Image.Image], W: int, L: int, H: int, tolerance: float = 40.0):
    """Returns (filled[z, y, x] bool, colour[z, y, x, 3] uint8). z=0 is the ground."""
    top_m, top_c = silhouette(views["top"], (W, L), tolerance)        # [y, x]
    side_m, side_c = silhouette(views["side"], (L, H), tolerance)     # [row, y]; front on the left
    front_m, front_c = silhouette(views["front"], (W, H), tolerance)  # [row, col]; mirrored x
    back_m, back_c = silhouette(views["back"], (W, H), tolerance)     # [row, x]

    # Re-index everything to [z, ...] with z = 0 at the ground (image rows go top-down).
    side_m, side_c = side_m[::-1], side_c[::-1]                       # [z, y]
    front_m, front_c = front_m[::-1, ::-1], front_c[::-1, ::-1]       # [z, x] (unmirrored)
    back_m, back_c = back_m[::-1], back_c[::-1]                       # [z, x]

    filled = (top_m[None, :, :]
              & side_m[:, :, None]
              & (front_m & back_m)[:, None, :])   # front and back see the same projection, mirrored

    colour = np.zeros((H, L, W, 3), np.uint8)
    colour[:] = side_c[:, :, None, :]                                 # default: the side view
    front_face = filled & exposed(filled, 1, 1)                       # nothing at y-1
    back_face = filled & exposed(filled, 1, -1)                       # nothing at y+1
    colour[front_face] = np.broadcast_to(front_c[:, None, :, :], colour.shape)[front_face]
    colour[back_face] = np.broadcast_to(back_c[:, None, :, :], colour.shape)[back_face]
    top_face = filled & exposed(filled, 0, -1)                        # nothing at z+1
    colour[top_face] = np.broadcast_to(top_c[None, :, :, :], colour.shape)[top_face]
    return filled, colour


def exposed(filled: np.ndarray, axis: int, shift: int) -> np.ndarray:
    """True where the neighbour at index - shift along axis is empty (outside the box counts
    as empty). shift=+1 on axis 1 asks "is there nothing in front (y-1)?"."""
    neighbour = np.roll(filled, shift, axis=axis)
    wrapped = [slice(None)] * filled.ndim
    wrapped[axis] = 0 if shift > 0 else filled.shape[axis] - 1
    neighbour[tuple(wrapped)] = False
    return ~neighbour


def to_slices(filled: np.ndarray, colour: np.ndarray, colors: int = 0) -> list[Image.Image]:
    H, L, W = filled.shape
    rgba = np.zeros((H, L, W, 4), np.uint8)
    rgba[..., :3] = colour
    rgba[..., 3] = filled * 255
    slices = [Image.fromarray(rgba[z], "RGBA") for z in range(H)]
    if colors:
        # One shared palette for every slice keeps the pixel-art look consistent.
        strip = Image.new("RGB", (W * H, L))
        for z, s in enumerate(slices):
            strip.paste(s.convert("RGB"), (z * W, 0))
        pal = strip.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)
        out = []
        for s in slices:
            q = s.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGBA")
            q.putalpha(s.getchannel("A"))
            out.append(q)
        slices = out
    return slices


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--size", type=int, nargs=3, metavar=("W", "L", "H"), required=True)
    p.add_argument("--colors", type=int, default=16, help="shared palette size (0 = keep all)")
    p.add_argument("--bg-tolerance", type=float, default=40.0)
    a = p.parse_args()
    W, L, H = a.size
    views = quadrants(Image.open(a.src).convert("RGBA"))
    filled, colour = carve(views, W, L, H, a.bg_tolerance)
    slices = to_slices(filled, colour, a.colors)
    sheet = Image.new("RGBA", (W * H, L), (0, 0, 0, 0))
    for z, s in enumerate(slices):
        sheet.paste(s, (z * W, 0))
    sheet.save(a.dst)
    print(f"wrote {a.dst}: {H} slices of {W}x{L}px, {int(filled.sum())} voxels")


if __name__ == "__main__":
    main()
