import sys
from pathlib import Path

import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import build_stacks  # noqa: E402
import vox  # noqa: E402

RED = (200, 0, 0, 255)


@pytest.fixture
def dirs(tmp_path, monkeypatch):
    for name in ("VOX", "VIEWS", "OUT"):
        (tmp_path / name).mkdir()
        monkeypatch.setattr(build_stacks, name, tmp_path / name)
    monkeypatch.setattr(build_stacks, "ROOT", tmp_path)
    return tmp_path


def write_box(path, size):
    pal = [(0, 0, 0, 0)] * 256
    pal[1] = RED
    sx, sy, sz = size
    vox.write(path, vox.Model(size, [(x, y, z, 1) for x in range(sx) for y in range(sy) for z in range(sz)], pal))


def test_a_vox_model_wins_over_the_placeholder(dirs):
    write_box(dirs / "VOX/shrub.vox", (10, 10, 6))
    assert "from VOX/shrub.vox" in build_stacks.build("shrub")
    sheet = Image.open(dirs / "OUT/shrub/shrub_slices.png")
    assert sheet.size == (60, 10)
    assert sheet.getpixel((0, 0)) == RED


def test_a_vox_model_of_the_wrong_size_is_refused(dirs):
    write_box(dirs / "VOX/shrub.vox", (10, 10, 5))
    with pytest.raises(SystemExit, match="contract"):
        build_stacks.build("shrub")


def test_without_a_vox_or_views_it_falls_back_to_the_placeholder(dirs):
    assert "placeholder" in build_stacks.build("shrub")
