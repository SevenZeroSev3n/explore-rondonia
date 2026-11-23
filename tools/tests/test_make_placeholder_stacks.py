import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import make_placeholder_stacks as mps  # noqa: E402


def test_every_stack_has_equal_size_slices():
    for name, build in mps.STACKS.items():
        slices = build()
        sizes = {s.size for s in slices}
        assert len(sizes) == 1, f"{name}: mixed slice sizes {sizes}"


def test_sheet_is_one_row_with_width_divisible_by_count():
    slices = mps.pickup_slices()
    sheet = mps.to_sheet(slices)
    w, h = slices[0].size
    assert sheet.size == (w * len(slices), h)


def test_sheet_keeps_ground_slice_on_the_left():
    slices = mps.pickup_slices()
    sheet = mps.to_sheet(slices)
    w, h = slices[0].size
    assert list(sheet.crop((0, 0, w, h)).getdata()) == list(slices[0].getdata())


def test_ground_slice_of_truck_only_has_tyres():
    ground = mps.pickup_slices()[0]
    colours = {px for px in ground.getdata() if px[3] > 0}
    assert colours == {mps.TYRE}


def test_truck_bed_is_hollow_from_above():
    # z5 draws only the bed walls: the bed's inside stays transparent so the floor shows.
    z5 = mps.pickup_slices()[5]
    assert z5.getpixel((10, 25))[3] == 0
    assert z5.getpixel((2, 25))[3] > 0


def test_tree_is_deterministic():
    a = mps.to_sheet(mps.castanheira_slices(seed=1))
    b = mps.to_sheet(mps.castanheira_slices(seed=1))
    assert a.tobytes() == b.tobytes()
