"""Voxel models built in code, written as MagicaVoxel files into art/vox/ (ADR 0004).

These are a starting point: open the .vox in MagicaVoxel, touch it up and save it. The file in
art/vox/ is then the source of truth, so this script never overwrites one without --force.
Sizes follow build_stacks.STACKS (the contract with the game).

Models are written row by row from the FRONT (r = 0 is the front of the object, the top row of a
slice); `put` turns that into MagicaVoxel's +Y-forward axes.

Usage:
  python3 tools/vox_models.py [--only NAME ...] [--force]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_stacks  # noqa: E402
import vox  # noqa: E402


def hexrgb(h: str) -> tuple[int, int, int, int]:
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255)


class Builder:
    """A W x L x H grid addressed as (x, r, z): r counts rows from the front."""

    def __init__(self, name: str, colours: dict[str, str]):
        self.W, self.L, self.H, _ = build_stacks.STACKS[name]
        self.index = {key: i for i, key in enumerate(colours, start=1)}
        self.palette = [(0, 0, 0, 0)] * 256
        for key, i in self.index.items():
            self.palette[i] = hexrgb(colours[key])
        self.cells: dict[tuple[int, int, int], int] = {}

    def put(self, x: int, r: int, z: int, colour: str | None) -> None:
        if not (0 <= x < self.W and 0 <= r < self.L and 0 <= z < self.H):
            raise ValueError(f"({x}, {r}, {z}) is outside {self.W}x{self.L}x{self.H}")
        if colour is None:
            self.cells.pop((x, r, z), None)
        else:
            self.cells[(x, r, z)] = self.index[colour]

    def box(self, x0: int, x1: int, r0: int, r1: int, z0: int, z1: int, colour: str | None) -> None:
        """Fill the inclusive box; colour None carves it out."""
        for x in range(x0, x1 + 1):
            for r in range(r0, r1 + 1):
                for z in range(z0, z1 + 1):
                    self.put(x, r, z, colour)

    def model(self) -> vox.Model:
        voxels = [(x, self.L - 1 - r, z, i) for (x, r, z), i in sorted(self.cells.items())]
        return vox.Model((self.W, self.L, self.H), voxels, self.palette)


def locomotive() -> vox.Model:
    """Early-1900s narrow-gauge steam locomotive, 18 x 40 x 17 (art/views/02-madeira-mamore.md).

    Boiler and smokestack at the front, four pairs of red-spoked driving wheels joined by a side
    rod, a slatted cowcatcher, and an open cab at the back with real window holes and an open
    rear, which the four-view route cannot make.
    """
    b = Builder("locomotive", {
        "iron": "#28282e", "iron_light": "#46464e", "iron_dark": "#1c1c22", "red": "#962822",
        "red_dark": "#6e1c18", "brass": "#b8923a", "roof": "#3a3a40", "roof_light": "#4e4e56",
        "lamp": "#f0dc8c", "fire": "#d86a2a",
    })

    # Driving wheels: discs in the (r, z) plane, two voxels thick on each side.
    for centre in (10, 17, 24, 31):
        for r in range(centre - 3, centre + 3):
            for z in range(0, 6):
                d = ((r + 0.5 - centre) ** 2 + (z + 0.5 - 3) ** 2) ** 0.5
                if d > 3.0:
                    continue
                colour = "iron" if d >= 2.2 else "brass" if d < 0.9 else "red"
                for x in (1, 2, 15, 16):
                    b.put(x, r, z, colour)
    b.box(0, 0, 10, 31, 2, 2, "iron_light")             # side rods joining the wheels
    b.box(17, 17, 10, 31, 2, 2, "iron_light")

    b.box(3, 14, 3, 38, 2, 5, "iron")                   # frame between the wheels
    b.box(1, 16, 3, 38, 6, 6, "iron_light")             # running board / cab floor
    b.box(1, 1, 3, 27, 6, 6, "red")                     # red edge along the running board
    b.box(16, 16, 3, 27, 6, 6, "red")
    for r in (3, 39):                                   # buffer beams
        b.box(1, 16, r, r, 3, 5, "red")
    b.box(8, 9, 39, 39, 3, 3, "brass")                  # rear coupler

    for r, (x0, x1, top) in enumerate([(6, 11, 2), (4, 13, 3), (2, 15, 4)]):  # cowcatcher slats
        for x in range(x0, x1 + 1):
            b.box(x, x, r, r, 0, top, "red" if x % 2 else "red_dark")
    b.box(8, 9, 2, 2, 4, 4, "brass")                    # front coupler

    b.box(1, 3, 3, 7, 3, 5, "iron_light")               # cylinders
    b.box(14, 16, 3, 7, 3, 5, "iron_light")
    b.box(1, 3, 3, 3, 4, 4, "brass")
    b.box(14, 16, 3, 3, 4, 4, "brass")

    # Boiler: a slightly wide cylinder along r (z 7..12), darker smokebox at the front, brass bands.
    for r in range(3, 28):
        for x in range(18):
            for z in range(7, 13):
                if ((x + 0.5 - 9) / 3.8) ** 2 + ((z + 0.5 - 10) / 3.2) ** 2 <= 1:
                    colour = "iron_dark" if r <= 7 else "brass" if r in (12, 20) else "iron"
                    b.put(x, r, z, colour)
    b.box(8, 9, 3, 3, 9, 10, "brass")                   # smokebox door handle
    b.box(4, 4, 8, 26, 11, 11, "iron_light")            # handrails
    b.box(13, 13, 8, 26, 11, 11, "iron_light")

    b.box(8, 9, 3, 4, 13, 13, "brass")                  # headlamp
    b.box(8, 9, 3, 3, 13, 13, "lamp")
    b.box(7, 10, 5, 8, 13, 15, "iron")                  # smokestack
    b.box(6, 11, 4, 9, 16, 16, "iron_light")            # flared top, dark inside
    b.box(7, 10, 5, 8, 16, 16, "iron_dark")

    b.box(7, 10, 14, 17, 13, 13, "iron")                # steam dome with a brass cap
    for x, r in ((7, 14), (10, 14), (7, 17), (10, 17)):
        b.put(x, r, 13, None)
    b.box(8, 9, 15, 16, 14, 14, "brass")
    b.box(8, 9, 21, 22, 13, 13, "iron")                 # sand dome
    b.box(9, 9, 26, 26, 13, 14, "brass")                # whistle

    # Cab: red lower panels, iron upper walls with window holes, open rear, overhanging roof.
    b.box(1, 16, 28, 39, 7, 13, "iron")
    b.box(2, 15, 29, 38, 7, 13, None)                   # hollow inside
    b.box(1, 1, 28, 39, 7, 9, "red")
    b.box(16, 16, 28, 39, 7, 9, "red")
    b.box(1, 16, 28, 28, 7, 9, "red")
    for x in (1, 16):                                   # side windows, a pillar between them
        b.box(x, x, 30, 32, 10, 12, None)
        b.box(x, x, 34, 37, 10, 12, None)
    b.box(2, 4, 28, 28, 11, 12, None)                   # front windows beside the boiler
    b.box(13, 15, 28, 28, 11, 12, None)
    b.box(5, 12, 39, 39, 7, 12, None)                   # open rear
    b.box(6, 11, 29, 29, 7, 12, "iron_dark")            # backhead inside the cab
    b.box(8, 9, 29, 29, 8, 8, "fire")                   # firebox door glow
    b.box(7, 7, 29, 29, 11, 11, "brass")                # gauges
    b.box(10, 10, 29, 29, 11, 11, "brass")
    b.box(0, 17, 27, 39, 14, 14, "roof")
    b.box(2, 15, 28, 38, 15, 15, "roof_light")
    return b.model()


MODELS = {"locomotive": locomotive}


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--only", nargs="*", choices=sorted(MODELS))
    p.add_argument("--force", action="store_true", help="overwrite an existing art/vox/<name>.vox")
    a = p.parse_args()
    for name in a.only or MODELS:
        dst = build_stacks.VOX / f"{name}.vox"
        if dst.exists() and not a.force:
            print(f"{name}: {dst.relative_to(build_stacks.ROOT)} exists, kept (use --force to overwrite)")
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        model = MODELS[name]()
        vox.write(dst, model)
        print(f"{name}: wrote {dst.relative_to(build_stacks.ROOT)} ({len(model.voxels)} voxels)")


if __name__ == "__main__":
    main()
