"""Read and write MagicaVoxel .vox files, and turn a model into slices (ADR 0004).

Only the single-model part of the format is used: SIZE, XYZI and RGBA chunks. Every other chunk
that MagicaVoxel writes (scene graph, layers, materials, camera) is skipped on read.

Axes: MagicaVoxel is Z-up. In this project a model's front points to +Y, x runs left to right
and z is height. Seen from above (x right, +Y up) that is exactly a slice image with the front
on the top row, so slices come out unmirrored and facing up (-Y on screen), as the game expects.

Palette: voxel colour indices are 1..255; index i is palette[i]. palette[0] is unused.
"""
from __future__ import annotations

import struct
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image

RGBA = tuple[int, int, int, int]
Voxel = tuple[int, int, int, int]          # x, y, z, colour index (1..255)


@dataclass
class Model:
    size: tuple[int, int, int]              # (x, y, z) = (W, L, H)
    voxels: list[Voxel] = field(default_factory=list)
    palette: list[RGBA] = field(default_factory=lambda: [(0, 0, 0, 0)] * 256)


def _chunk(cid: bytes, content: bytes, children: bytes = b"") -> bytes:
    return cid + struct.pack("<ii", len(content), len(children)) + content + children


def write(path: str | Path, model: Model) -> None:
    sx, sy, sz = model.size
    for x, y, z, i in model.voxels:
        if not (0 <= x < sx and 0 <= y < sy and 0 <= z < sz and 1 <= i <= 255):
            raise ValueError(f"voxel {(x, y, z, i)} is outside {model.size} or has no colour")
    size = _chunk(b"SIZE", struct.pack("<iii", sx, sy, sz))
    xyzi = _chunk(b"XYZI", struct.pack("<i", len(model.voxels))
                  + b"".join(struct.pack("<BBBB", *v) for v in model.voxels))
    # The RGBA chunk stores colour index i at entry i-1.
    pal = list(model.palette[1:256]) + [(0, 0, 0, 0)]
    rgba = _chunk(b"RGBA", b"".join(struct.pack("<BBBB", *c) for c in pal))
    Path(path).write_bytes(b"VOX " + struct.pack("<i", 150) + _chunk(b"MAIN", b"", size + xyzi + rgba))


def read(path: str | Path) -> Model:
    data = Path(path).read_bytes()
    if data[:4] != b"VOX " or data[8:12] != b"MAIN":
        raise ValueError(f"{path} is not a MagicaVoxel .vox file")
    sizes, xyzis, rgba = [], [], None
    pos = 20 + struct.unpack_from("<i", data, 12)[0]
    end = pos + struct.unpack_from("<i", data, 16)[0]
    while pos < end:
        cid = data[pos:pos + 4]
        n, m = struct.unpack_from("<ii", data, pos + 4)
        body = data[pos + 12:pos + 12 + n]
        if cid == b"SIZE":
            sizes.append(struct.unpack_from("<iii", body))
        elif cid == b"XYZI":
            count = struct.unpack_from("<i", body)[0]
            xyzis.append([struct.unpack_from("<BBBB", body, 4 + 4 * k) for k in range(count)])
        elif cid == b"RGBA":
            rgba = [struct.unpack_from("<BBBB", body, 4 * k) for k in range(256)]
        pos += 12 + n + m
    if len(sizes) != 1 or len(xyzis) != 1:
        raise ValueError(f"{path}: expected one model, found {len(sizes)} (merge the models in MagicaVoxel)")
    if rgba is None:
        raise ValueError(f"{path}: no palette (RGBA chunk); save it again from MagicaVoxel")
    return Model(sizes[0], xyzis[0], [(0, 0, 0, 0)] + rgba[:255])


def to_slices(model: Model) -> list[Image.Image]:
    """One RGBA image per z (ground first), W x L, front (+Y) on the top row."""
    sx, sy, sz = model.size
    slices = [Image.new("RGBA", (sx, sy), (0, 0, 0, 0)) for _ in range(sz)]
    for x, y, z, i in model.voxels:
        r, g, b, _ = model.palette[i]
        slices[z].putpixel((x, sy - 1 - y), (r, g, b, 255))
    return slices
