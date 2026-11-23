import sys
from pathlib import Path

import numpy as np
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
