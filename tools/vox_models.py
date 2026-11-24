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
    """Early-1900s narrow-gauge steam locomotive, 24 x 53 x 23 (art/views/02-madeira-mamore.md).

    Boiler and smokestack at the front, four pairs of red-spoked driving wheels joined by a side
    rod, a slatted cowcatcher, and an open cab at the back with real window holes and an open
    rear, which the four-view route cannot make.
    """
    b = Builder("locomotive", {
        "iron": "#28282e", "iron_light": "#46464e", "iron_dark": "#1c1c22", "red": "#962822",
        "red_dark": "#6e1c18", "brass": "#b8923a", "roof": "#3a3a40", "roof_light": "#4e4e56",
        "lamp": "#f0dc8c", "fire": "#d86a2a",
    })

    # Driving wheels: discs in the (r, z) plane (radius 4), two voxels thick on each side, with an
    # iron tyre, eight red spokes and a brass hub.
    for centre in (14, 23, 32, 41):
        for r in range(centre - 4, centre + 4):
            for z in range(0, 8):
                dr, dz = r + 0.5 - centre, z + 0.5 - 4
                d = (dr * dr + dz * dz) ** 0.5
                if d > 4.0:
                    continue
                if d >= 3.1:
                    colour = "iron"
                elif d < 1.2:
                    colour = "brass"
                elif abs(dr) < 0.6 or abs(dz) < 0.6 or abs(abs(dr) - abs(dz)) < 0.6:
                    colour = "red"
                else:
                    colour = "red_dark"
                for x in (2, 3, 20, 21):
                    b.put(x, r, z, colour)
    b.box(1, 1, 14, 41, 3, 3, "iron_light")             # side rods joining the wheels
    b.box(22, 22, 14, 41, 3, 3, "iron_light")

    b.box(4, 19, 4, 51, 3, 7, "iron")                   # frame between the wheels
    b.box(1, 22, 4, 52, 8, 8, "iron_light")             # running board / cab floor
    b.box(1, 1, 4, 36, 8, 8, "red")                     # red edge along the running board
    b.box(22, 22, 4, 36, 8, 8, "red")
    for r in (4, 52):                                   # buffer beams
        b.box(1, 22, r, r, 4, 7, "red")
    b.box(11, 12, 52, 52, 5, 5, "brass")                # rear coupler

    slats = [(8, 15, 2), (6, 17, 3), (4, 19, 4), (3, 20, 5)]
    for r, (x0, x1, top) in enumerate(slats):           # cowcatcher, sloping up to the beam
        for x in range(x0, x1 + 1):
            b.box(x, x, r, r, 0, top, "red" if x % 2 else "red_dark")
    b.box(11, 12, 3, 3, 6, 6, "brass")                  # front coupler

    b.box(1, 4, 5, 10, 4, 7, "iron_light")              # cylinders
    b.box(19, 22, 5, 10, 4, 7, "iron_light")
    b.box(1, 4, 5, 5, 5, 6, "brass")
    b.box(19, 22, 5, 5, 5, 6, "brass")

    # Boiler: a slightly wide cylinder along r (z 9..17), darker smokebox at the front, brass bands.
    for r in range(4, 37):
        for x in range(24):
            for z in range(9, 18):
                if ((x + 0.5 - 12) / 5.1) ** 2 + ((z + 0.5 - 13.4) / 4.3) ** 2 <= 1:
                    colour = "iron_dark" if r <= 10 else "brass" if r in (16, 27, 36) else "iron"
                    b.put(x, r, z, colour)
    b.box(11, 12, 4, 4, 12, 13, "brass")                # smokebox door handle
    b.box(6, 6, 11, 35, 15, 15, "iron_light")           # handrails
    b.box(17, 17, 11, 35, 15, 15, "iron_light")

    b.box(11, 12, 4, 5, 18, 19, "brass")                # headlamp
    b.box(11, 12, 4, 4, 18, 19, "lamp")
    b.box(10, 13, 7, 10, 18, 21, "iron")                # smokestack
    b.box(9, 14, 6, 11, 22, 22, "iron_light")           # flared top, dark inside
    b.box(10, 13, 7, 10, 22, 22, "iron_dark")

    b.box(10, 13, 19, 22, 18, 19, "iron")               # steam dome with a brass cap
    for x, r in ((10, 19), (13, 19), (10, 22), (13, 22)):
        b.put(x, r, 19, None)
    b.box(11, 12, 20, 21, 20, 20, "brass")
    b.box(11, 12, 28, 29, 18, 18, "iron")               # sand dome
    b.box(12, 12, 35, 35, 18, 20, "brass")              # whistle

    # Cab: red lower panels, iron upper walls with window holes, open rear, overhanging roof.
    b.box(1, 22, 37, 52, 9, 18, "iron")
    b.box(2, 21, 38, 51, 9, 18, None)                   # hollow inside
    b.box(1, 1, 37, 52, 9, 12, "red")
    b.box(22, 22, 37, 52, 9, 12, "red")
    b.box(1, 22, 37, 37, 9, 12, "red")
    for x in (1, 22):                                   # side windows, a pillar between them
        b.box(x, x, 40, 43, 13, 16, None)
        b.box(x, x, 46, 50, 13, 16, None)
    b.box(2, 5, 37, 37, 14, 16, None)                   # front windows beside the boiler
    b.box(18, 21, 37, 37, 14, 16, None)
    b.box(6, 17, 52, 52, 9, 16, None)                   # open rear
    b.box(8, 15, 38, 38, 9, 16, "iron_dark")            # backhead inside the cab
    b.box(11, 12, 38, 38, 10, 11, "fire")               # firebox door glow
    b.box(9, 9, 38, 38, 15, 15, "brass")                # gauges
    b.box(14, 14, 38, 38, 15, 15, "brass")
    b.box(0, 23, 36, 52, 19, 19, "roof")
    b.box(2, 21, 37, 51, 20, 20, "roof_light")
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
