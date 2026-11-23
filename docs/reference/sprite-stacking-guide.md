# Sprite Stacking Project Setup Guide

A practical guide to setting up a project folder for a top-down game that uses **sprite stacking**, the technique of faking 3D by drawing flat pixel-art slices on top of each other.

Based on the approach described in [SpriteCook: Sprite Stacking Pixel Art](https://www.spritecook.ai/blog/sprite-stacking-pixel-art). The code here is written fresh for this guide and targets **Godot 4.x** (the article tested on Godot 4.6).

---

## 1. How it works (30-second version)

- An object is cut into horizontal **slices**, one per pixel of height (like a CT scan).
- In-game, slices are drawn **bottom to top**, each one lifted **1 screen pixel** higher.
- To turn the object, rotate **every slice by the same angle**. One small sheet covers all 360°, so you never draw a separate sprite per direction.
- Squashing the stack vertically (e.g. `0.75`) fakes a lower camera angle.

```
slice sheet (one row, ground → top)

[ 0 ][ 1 ][ 2 ][ 3 ] ... [ 14 ]
  ↑ ground                  ↑ roof
```

---

## 2. Tools to install

| Tool | Required? | Why |
|---|---|---|
| **Godot 4.x** (4.6 tested) | Yes | Engine and renderer |
| **MagicaVoxel** (free) | Recommended | Model objects as voxels and export slices directly. Only route that supports holes and overhangs. |
| **Python 3.10+** with `pillow` and `numpy` | Recommended | Repack or validate slice sheets |
| **Aseprite / LibreSprite / Pixelorama** | Optional | Touch up slices by hand |
| **Git** | Recommended | Version control (see `.gitignore` below) |
| SpriteCook generator / MCP tools | Optional | Browser slicer or AI generation of the 4 flat views (paid credits for generation) |

---

## 3. Folder structure

```
my-stack-game/
├── README.md
├── .gitignore
├── art/                        # SOURCE art (not loaded by the game)
│   ├── vox/                    # MagicaVoxel .vox files
│   │   └── car.vox
│   ├── views/                  # optional: 4-view sheets (top/side/front/back)
│   │   └── car_views.png
│   └── exports/                # raw exports straight from MagicaVoxel
│       └── car_raw.png
├── tools/                      # pipeline scripts
│   ├── requirements.txt
│   └── repack_slices.py
└── game/                       # the Godot project (project.godot lives here)
    ├── project.godot
    ├── assets/
    │   └── stacks/
    │       └── car/
    │           └── car_slices.png   # FINAL sheet: one row, ground → top
    ├── scripts/
    │   └── sprite_stack.gd
    └── scenes/
        ├── car.tscn
        └── world.tscn
```

Why this split:

- `art/` holds editable sources. The game never loads them, so Godot doesn't import junk.
- `tools/` turns sources into game-ready sheets. Keep it reproducible.
- `game/assets/stacks/<name>/` holds only final sheets, one folder per object.

Create it in one go (macOS / Linux / Git Bash):

```bash
mkdir -p my-stack-game/{art/{vox,views,exports},tools,game/{assets/stacks,scripts,scenes}}
cd my-stack-game && git init
```

Then open Godot → **Import / New Project** → pick the `game/` folder.

---

## 4. `.gitignore`

```gitignore
# Godot
game/.godot/
game/*.translation
*.import.tmp

# Python
tools/.venv/
__pycache__/

# OS
.DS_Store
Thumbs.db
```

> Keep the `*.png.import` files committed: they store your import settings (nearest filter, no mipmaps).

---

## 5. Godot project settings

In **Project → Project Settings** (turn on *Advanced Settings*):

| Setting | Value | Why |
|---|---|---|
| `rendering/textures/canvas_textures/default_texture_filter` | **Nearest** | Crisp pixels, no blur when rotating |
| `display/window/size/viewport_width` / `height` | e.g. `320` × `180` | Low internal resolution |
| `display/window/size/window_width_override` / `height` | e.g. `1280` × `720` | Upscaled window |
| `display/window/stretch/mode` | `viewport` | Renders at low res, then scales up: real pixel art |
| `display/window/stretch/scale_mode` | `integer` | No uneven pixels |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | On | Reduces jitter |

On each slice PNG, the **Import** tab should have *Mipmaps* off. Click **Reimport** after changes.

---

## 6. Making the slice sheet

**Target format** (what the game script expects):

- One horizontal row of equal-size slices.
- **Leftmost = ground slice, rightmost = top slice.**
- Transparent background.
- Draw the object **facing up** (toward −Y) in every slice. The rotation math in step 7 assumes this.

Reference size from the article: a car of **15 slices × 24×43 px**.

### Route A: MagicaVoxel (recommended)

1. Model the object in MagicaVoxel. Keep it small (e.g. 24 × 43 × 15).
2. **Export → slice**. Save to `art/exports/<name>_raw.png`.
3. Open the result and check the orientation. If the slices are stacked vertically, or ordered top → ground, repack them with the script below.

### Route B: four flat views

Draw (or generate) **top, side, front, back** views at about **32×32 px**, in an orthographic 2×2 layout with a bold 1 px outline and flat fills. Then cut them into slices with SpriteCook's free browser **sprite stack generator** (no code) or the Python script from the article.

Limits: flat views **can't produce holes or overhangs**. Use MagicaVoxel for those.

### Repack script

`tools/requirements.txt`:

```
pillow
numpy
```

Setup:

```bash
cd tools
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

`tools/repack_slices.py`:

```python
"""Repack a slice strip into the game's format: one row, ground -> top.

Usage:
  python repack_slices.py IN.png OUT.png --count 15 [--vertical] [--reverse]

  --vertical  input slices are stacked top-to-bottom instead of left-to-right
  --reverse   input order is top -> ground (flip it)
"""
import argparse
from PIL import Image


def main():
    p = argparse.ArgumentParser()
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--count", type=int, required=True, help="number of slices")
    p.add_argument("--vertical", action="store_true")
    p.add_argument("--reverse", action="store_true")
    a = p.parse_args()

    img = Image.open(a.src).convert("RGBA")
    W, H = img.size
    if a.vertical:
        if H % a.count:
            raise SystemExit(f"height {H} not divisible by {a.count}")
        w, h = W, H // a.count
        boxes = [(0, i * h, w, (i + 1) * h) for i in range(a.count)]
    else:
        if W % a.count:
            raise SystemExit(f"width {W} not divisible by {a.count}")
        w, h = W // a.count, H
        boxes = [(i * w, 0, (i + 1) * w, h) for i in range(a.count)]

    slices = [img.crop(b) for b in boxes]
    if a.reverse:
        slices.reverse()

    out = Image.new("RGBA", (w * a.count, h), (0, 0, 0, 0))
    for i, s in enumerate(slices):
        out.paste(s, (i * w, 0))
    out.save(a.dst)
    print(f"wrote {a.dst}: {a.count} slices of {w}x{h}px")


if __name__ == "__main__":
    main()
```

Example:

```bash
python repack_slices.py ../art/exports/car_raw.png \
  ../game/assets/stacks/car/car_slices.png --count 15 --vertical
```

---

## 7. The stacking node (Godot)

`game/scripts/sprite_stack.gd`:

```gdscript
@tool
class_name SpriteStack
extends Node2D

## Slice sheet: one row, ground (left) -> top (right). Art faces UP (-Y).
@export var sheet: Texture2D:
	set(v): sheet = v; queue_redraw()
@export var slice_count: int = 15:
	set(v): slice_count = max(v, 1); queue_redraw()
@export var spacing: float = 1.0:     ## screen px between slices
	set(v): spacing = v; queue_redraw()
@export_range(0.5, 1.0, 0.05) var squash: float = 0.75:  ## <0.6 makes roofs thin
	set(v): squash = v; queue_redraw()
@export var angle: float = 0.0:       ## radians; the stack's facing
	set(v): angle = v; queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	if sheet == null:
		return
	var w := sheet.get_width() / slice_count
	var h := sheet.get_height()
	var dest := Rect2(-w / 2.0, -h / 2.0, w, h)  # centered on the node origin

	for z in slice_count:
		var lift := roundf(z * spacing)
		# rotate the slice, squash vertically (camera tilt), then lift it up
		var xf := Transform2D(angle, Vector2.ZERO).scaled(Vector2(1.0, squash))
		xf.origin = Vector2(0.0, -lift)
		draw_set_transform_matrix(xf)
		draw_texture_rect_region(sheet, dest, Rect2(z * w, 0, w, h))

	draw_set_transform_matrix(Transform2D.IDENTITY)
```

Because of `@tool`, the stack renders and rotates live in the editor when you change `angle` in the Inspector.

### Facing the direction of movement

Since the art faces up, convert velocity to an angle like this:

```gdscript
if velocity.length() > 0.1:
	stack.angle = atan2(velocity.y, velocity.x) + PI / 2.0
```

> The article writes this as `atan2(v.y, v.x) - PI/2`. The sign depends on which way your art faces. If the object drives sideways or backwards, flip the sign or add `PI`. For reversing vehicles, use their **heading**, not their velocity.

Round positions to whole pixels (`global_position = global_position.round()`) to reduce shimmer.

---

## 8. Scene setup and depth sorting

`car.tscn`:

```
Car (CharacterBody2D)        ← origin = where the object touches the ground
├── CollisionShape2D
└── SpriteStack              ← script: sprite_stack.gd, sheet: car_slices.png
```

`world.tscn`:

```
World (Node2D)
└── Entities (Node2D)        ← Ordering → Y Sort Enabled = ON
    ├── Car
    ├── Tree
    └── House
```

Sort **whole stacks** by their ground contact point. Never sort individual slices. With Y Sort on the parent, Godot handles this, as long as each object's origin sits at its base.

---

## 9. Checklist and common pitfalls

- [ ] Sheet is one row, ground on the left, width divisible by `slice_count`.
- [ ] Texture filter is **Nearest**, mipmaps off.
- [ ] Expected screen size: a 24×43 px slice with 15 slices covers about **24×52 px** at squash 1, and about **24×41 px** at squash 0.75.
- [ ] The front of the object follows the direction of movement.
- [ ] Stacks sort correctly when walking behind and in front of each other.

| Problem | Fix |
|---|---|
| Jitter or "crawling" pixels when rotating small sprites | Use a bigger pixel scale, round positions, or try RotSprite-style sampling (Scale2x upscale before rotation) |
| Lines inside the object | You outlined every slice. Remove those outlines and outline the **finished** stack once (e.g. a shader on a SubViewport). |
| Soft gradients or thin stripes smear | Use flat colors and chunkier details |
| Roof looks paper-thin | Raise `squash` above 0.6 |
| Many static props tank performance | Pre-render non-rotating stacks to a single sprite |

---

## 10. Adding a new object (routine)

1. Model it in `art/vox/<name>.vox`.
2. Export slices to `art/exports/<name>_raw.png`.
3. Run `repack_slices.py` into `game/assets/stacks/<name>/<name>_slices.png`.
4. In Godot, add a `SpriteStack` node, assign the sheet, and set `slice_count`.
5. Put the node's origin at the object's base, under a Y-sorted parent.
