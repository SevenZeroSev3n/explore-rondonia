import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import make_ground as mg  # noqa: E402


def test_pasture_tile_is_opaque_and_square():
    tile = mg.pasture_tile()
    assert tile.size == (mg.TILE, mg.TILE)
    assert tile.getchannel("A").getextrema() == (255, 255)


def test_every_decal_has_something_in_its_cell():
    atlas = mg.decal_atlas()
    assert atlas.size == (mg.CELL * len(mg.DECALS), mg.CELL)
    for i, name in enumerate(mg.DECALS):
        cell = atlas.crop((i * mg.CELL, 0, (i + 1) * mg.CELL, mg.CELL))
        assert cell.getbbox() is not None, name


def test_drawing_is_deterministic():
    assert mg.pasture_tile().tobytes() == mg.pasture_tile().tobytes()
    assert mg.decal_atlas().tobytes() == mg.decal_atlas().tobytes()
