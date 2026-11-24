import sys
from pathlib import Path

import numpy as np
import pytest
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import views_to_slices as v2s  # noqa: E402

BG = (255, 255, 255, 255)


def sheet(draw_views):
    """A 2x2 views sheet on white, 200x200 per quadrant; draw_views(quadrant_name, draw, origin)."""
    img = Image.new("RGBA", (400, 400), BG)
    d = ImageDraw.Draw(img)
    for name, origin in {"top": (0, 0), "side": (200, 0), "front": (0, 200), "back": (200, 200)}.items():
        draw_views(name, d, origin)
    return img


def box_views(name, d, o):
    x, y = o
    d.rectangle([x + 50, y + 50, x + 149, y + 149], fill={"top": (200, 0, 0, 255), "side": (0, 200, 0, 255),
                                                          "front": (0, 0, 200, 255), "back": (200, 200, 0, 255)}[name])


def test_quadrants_split_the_sheet():
    q = v2s.quadrants(Image.new("RGBA", (100, 60)))
    assert {k: im.size for k, im in q.items()} == {k: (50, 30) for k in ("top", "side", "front", "back")}


def test_a_box_fills_the_whole_volume():
    filled, _ = v2s.carve(v2s.quadrants(sheet(box_views)), 6, 8, 5)
    assert filled.shape == (5, 8, 6)
    assert filled.all()


def test_faces_take_colour_from_the_view_that_sees_them():
    filled, colour = v2s.carve(v2s.quadrants(sheet(box_views)), 6, 8, 5)
    assert tuple(colour[4, 3, 3]) == (200, 0, 0)      # top face <- top view
    assert tuple(colour[2, 0, 3]) == (0, 0, 200)      # front face (y = 0) <- front view
    assert tuple(colour[2, 7, 3]) == (200, 200, 0)    # back face <- back view
    assert tuple(colour[2, 3, 0]) == (0, 200, 0)      # side face <- side view


def test_side_view_carves_a_low_front():
    # Side view: front (left) half is short, back half tall -> like a truck cab at the back.
    def views(name, d, o):
        x, y = o
        if name == "side":
            d.rectangle([x + 20, y + 100, x + 99, y + 179], fill=(0, 0, 0, 255))   # front, low
            d.rectangle([x + 100, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))  # back, tall
        else:
            d.rectangle([x + 20, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))
    filled, _ = v2s.carve(v2s.quadrants(sheet(views)), 4, 8, 8)
    assert not filled[7, 0].any(), "the front is low: nothing at the top slice"
    assert filled[7, 7].all(), "the back reaches the top"
    assert filled[0].all(), "everything touches the ground"


def test_front_view_is_mirrored_into_object_space():
    # Front view: only the viewer's LEFT half drawn = the object's RIGHT side (x high).
    def views(name, d, o):
        x, y = o
        if name == "front":
            d.rectangle([x + 20, y + 20, x + 99, y + 179], fill=(0, 0, 0, 255))
            d.rectangle([x + 100, y + 20, x + 179, y + 21], fill=(0, 0, 0, 255))  # keeps the crop full width
        elif name == "back":
            # From behind, the object's right side is on the viewer's RIGHT.
            d.rectangle([x + 100, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))
            d.rectangle([x + 20, y + 20, x + 99, y + 21], fill=(0, 0, 0, 255))
        else:
            d.rectangle([x + 20, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))
    filled, _ = v2s.carve(v2s.quadrants(sheet(views)), 8, 4, 8)
    assert filled[3, :, 6].all() and not filled[3, :, 1].any()


def test_slices_are_transparent_outside_and_palette_limited():
    filled, colour = v2s.carve(v2s.quadrants(sheet(box_views)), 6, 8, 5)
    filled[:, :, 0] = False
    slices = v2s.to_slices(filled, colour, colors=4)
    assert len(slices) == 5 and slices[0].size == (6, 8)
    assert slices[0].getpixel((0, 0))[3] == 0
    colours = {px[:3] for s in slices for px in s.getdata() if px[3]}
    assert len(colours) <= 4


def test_exposed_treats_outside_as_empty():
    f = np.ones((1, 3, 1), bool)
    assert list(v2s.exposed(f, 1, 1)[0, :, 0]) == [True, False, False]
    assert list(v2s.exposed(f, 1, -1)[0, :, 0]) == [False, False, True]


def test_build_stacks_contract_matches_the_placeholders():
    import build_stacks
    import make_placeholder_stacks as mps
    for name, (W, L, H, _) in build_stacks.STACKS.items():
        slices = mps.STACKS[name]()
        assert (slices[0].size, len(slices)) == ((W, L), H), name


def test_grid_lines_between_the_cells_are_ignored():
    # Generators often draw the 2x2 grid (and a frame) even when asked not to. The lines must not
    # count as part of the object, or every view gets cropped to the whole cell.
    def views(name, d, o):
        x, y = o
        if name == "side":
            d.rectangle([x + 20, y + 100, x + 99, y + 179], fill=(0, 0, 0, 255))   # front, low
            d.rectangle([x + 100, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))  # back, tall
        else:
            d.rectangle([x + 20, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))
    img = sheet(views)
    d = ImageDraw.Draw(img)
    grey = (200, 200, 200, 255)
    d.line([(199, 0), (199, 399)], fill=grey, width=3)
    d.line([(0, 199), (399, 199)], fill=grey, width=3)
    clean, _ = v2s.carve(v2s.quadrants(sheet(views)), 4, 8, 8)
    lined, _ = v2s.carve(v2s.quadrants(img), 4, 8, 8)
    assert (lined == clean).all()
    d.rectangle([0, 0, 399, 399], outline=grey, width=2)            # and a frame round the sheet
    framed, _ = v2s.carve(v2s.quadrants(img), 4, 8, 8)
    assert (framed == clean).all()


def test_lower_tolerance_keeps_a_light_object_on_a_light_background():
    # A near-white body (like the white truck) on a flat light-grey background. The side view is a
    # step (low front, tall back), so a carve that lost the body would fail the shape checks.
    light_bg, body = (240, 240, 240, 255), (225, 222, 210, 255)
    img = Image.new("RGBA", (400, 400), light_bg)
    d = ImageDraw.Draw(img)
    for name, (x, y) in {"top": (0, 0), "side": (200, 0), "front": (0, 200), "back": (200, 200)}.items():
        if name == "side":
            d.rectangle([x + 20, y + 100, x + 99, y + 179], fill=body)
            d.rectangle([x + 100, y + 20, x + 179, y + 179], fill=body)
        else:
            d.rectangle([x + 20, y + 20, x + 179, y + 179], fill=body)
    with pytest.raises(ValueError, match="no object"):
        v2s.carve(v2s.quadrants(img), 4, 8, 8)
    filled, _ = v2s.carve(v2s.quadrants(img), 4, 8, 8, tolerance=12)
    assert filled[0].all(), "the whole footprint touches the ground"
    assert filled[7, 7].all() and not filled[7, 0].any(), "tall back, low front"


def test_lower_cover_keeps_a_thin_trunk():
    def tree(name, d, o):
        x, y = o
        if name == "top":
            d.ellipse([x + 20, y + 20, x + 179, y + 179], fill=(0, 120, 0, 255))
        else:
            d.ellipse([x + 20, y + 20, x + 179, y + 99], fill=(0, 120, 0, 255))   # crown
            d.rectangle([x + 97, y + 100, x + 102, y + 179], fill=(90, 60, 30, 255))  # 6 px centred trunk
    # 7 voxels across 160 px: the centre voxel is ~23 px wide, so the trunk covers ~26% of it.
    lost, _ = v2s.carve(v2s.quadrants(sheet(tree)), 7, 7, 8)
    assert not lost[0].any(), "a trunk thinner than a voxel vanishes at the default cover"
    kept, _ = v2s.carve(v2s.quadrants(sheet(tree)), 7, 7, 8, cover=0.2)
    assert kept[0].any()


def test_a_grid_line_across_the_middle_of_a_cell_is_ignored():
    # Some generators put the grid off-centre, so a line can cross a cell well inside the edge band.
    def views(name, d, o):
        x, y = o
        if name == "side":
            d.rectangle([x + 20, y + 100, x + 99, y + 179], fill=(0, 0, 0, 255))
            d.rectangle([x + 100, y + 20, x + 179, y + 179], fill=(0, 0, 0, 255))
        else:
            d.rectangle([x + 40, y + 40, x + 159, y + 159], fill=(0, 0, 0, 255))
    clean, _ = v2s.carve(v2s.quadrants(sheet(views)), 4, 8, 8)
    img = sheet(views)
    d = ImageDraw.Draw(img)
    d.line([(0, 225), (399, 225)], fill=(200, 200, 200, 255), width=3)   # crosses front and back
    d.line([(75, 0), (75, 399)], fill=(200, 200, 200, 255), width=2)     # crosses top and front
    lined, _ = v2s.carve(v2s.quadrants(img), 4, 8, 8)
    assert (lined == clean).all()
