import struct
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import vox  # noqa: E402

RED = (200, 0, 0, 255)
BLUE = (0, 0, 200, 255)


def palette(*colours):
    """A palette whose index 1.. holds the given colours (index 0 is always empty)."""
    pal = [(0, 0, 0, 0)] * 256
    for i, c in enumerate(colours, start=1):
        pal[i] = c
    return pal


def test_write_then_read_gives_the_same_model(tmp_path):
    model = vox.Model((3, 4, 2), [(0, 0, 0, 1), (2, 3, 1, 2)], palette(RED, BLUE))
    vox.write(tmp_path / "m.vox", model)
    back = vox.read(tmp_path / "m.vox")
    assert back.size == (3, 4, 2)
    assert sorted(back.voxels) == sorted(model.voxels)
    assert back.palette[1] == RED and back.palette[2] == BLUE


def test_slices_are_ground_first_and_front_up(tmp_path):
    # x=0 on the left; the front of the object is +Y in MagicaVoxel and the top row in the slice.
    model = vox.Model((3, 4, 2), [(0, 3, 0, 1), (2, 0, 1, 2)], palette(RED, BLUE))
    slices = vox.to_slices(model)
    assert len(slices) == 2 and slices[0].size == (3, 4)
    assert slices[0].getpixel((0, 0)) == RED            # front-left, ground
    assert slices[1].getpixel((2, 3)) == BLUE           # back-right, top
    assert slices[0].getpixel((2, 3))[3] == 0           # everything else is clear


def test_reader_skips_chunks_it_does_not_know(tmp_path):
    # MagicaVoxel 0.99 writes scene-graph and material chunks after the model; they must not matter.
    path = tmp_path / "m.vox"
    vox.write(path, vox.Model((1, 1, 1), [(0, 0, 0, 1)], palette(RED)))
    data = bytearray(path.read_bytes())
    extra = b"nTRN" + struct.pack("<ii", 4, 0) + b"\x00" * 4
    data += extra
    struct.pack_into("<i", data, 16, struct.unpack_from("<i", data, 16)[0] + len(extra))
    path.write_bytes(bytes(data))
    assert vox.read(path).voxels == [(0, 0, 0, 1)]


def test_reader_refuses_several_models(tmp_path):
    path = tmp_path / "m.vox"
    vox.write(path, vox.Model((1, 1, 1), [(0, 0, 0, 1)], palette(RED)))
    data = bytearray(path.read_bytes())
    size = b"SIZE" + struct.pack("<ii", 12, 0) + struct.pack("<iii", 1, 1, 1)
    data += size
    struct.pack_into("<i", data, 16, struct.unpack_from("<i", data, 16)[0] + len(size))
    path.write_bytes(bytes(data))
    with pytest.raises(ValueError, match="one model"):
        vox.read(path)


def test_reader_refuses_a_file_that_is_not_vox(tmp_path):
    path = tmp_path / "m.vox"
    path.write_bytes(b"PNG nope")
    with pytest.raises(ValueError, match="not a MagicaVoxel"):
        vox.read(path)


def test_code_models_match_the_stack_contract():
    import build_stacks
    import vox_models

    for name, make in vox_models.MODELS.items():
        model = make()
        W, L, H, _ = build_stacks.STACKS[name]
        assert model.size == (W, L, H), name
        assert model.voxels, name
        slices = vox.to_slices(model)
        assert slices[0].getbbox() is not None, f"{name}: nothing touches the ground"
        assert slices[-1].getbbox() is not None, f"{name}: the top slice is empty"


def test_preview_draws_a_turntable_and_the_raw_slices():
    from PIL import Image

    import preview_stack

    sheet = Image.new("RGBA", (6 * 3, 8), (200, 0, 0, 255))
    out = preview_stack.preview(sheet, 3, scale=2)
    assert out.width >= 2 * 8 * len(preview_stack.ANGLES)
    assert out.getbbox() is not None
