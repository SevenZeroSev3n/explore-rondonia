# ADR 0005 — Visual style: 640×360, fixed palette

- Status: accepted
- Date: 2026-11-23

## Context

The guide suggests 320×180, which is too tight to read a map with cities and labels.

## Decision

- Internal resolution **480×270**, viewport stretch, integer scale (×4 = 1080p exact; ×2 with
  letterbox at 720p). Nearest filter, no mipmaps, 2D transforms snapped to pixel.
- A fixed palette of ~32 colours: Amazonian greens, red dirt roads, river blues.
- Outline drawn once on the finished stack, never per slice.
- UI font (2026-11-24): **Pixelify Sans** (OFL) at **13 px**, the size where its pixel grid lands
  on whole screen pixels and every Portuguese accent stays distinct (at 11 px "á" reads as "à"
  and "ã" loses its tilde); antialiasing and hinting off; set once in `game/assets/ui_theme.tres`.
- Place sheets (fichas) are pixel-framed with a bitmap font, but **real photos are shown at full
  resolution, not pixelated**, to mark the contrast between the game and the real place.
  Implementation (2026-11-24): on the web an HTML `<img>` is laid exactly over the photo frame
  (`scripts/ui/web_photo.gd`); the desktop build shows the photo inside the game-resolution frame.

## Update (2026-11-24): 640×360 and everything one third bigger

The owner asked for a bit more resolution and bigger, more detailed objects. The internal
resolution is now **640×360** (integer ×3 = 1080p and ×2 = 720p, both exact, no letterbox; the
desktop window opens at 1280×720). Everything measured in pixels grew by **4/3** so the world
looks the same size on screen with more detail:

- Slice sheets (`tools/build_stacks.py` `STACKS`, and the slice counts in the scenes,
  `forest.gd` and `diorama.gd`): e.g. truck 27×48×12, castanheira 32×32×35, locomotive
  24×53×23. The locomotive `.vox` was rebuilt at the new size; code-drawn placeholders are
  resampled to the contract.
- The map: `tools/geo/build_map.py` cruises at 120 px/s (was 90), so the scale is 0.082 px/m and
  the drive still takes 8 minutes; road, river, forest and chunk sizes, speeds, collision radii,
  diorama layout and place photo rules scaled with it.
- UI: layout ×4/3 and the font at **18 px** (13 × 4/3 ≈ 17.3; at 17 Pixelify Sans renders uneven
  strokes, at 18 its strokes and every accent are clean).

The 480×270 decision above is kept for history; this update replaces its numbers.


## Update (2026-11-24): the state map zoomed out

The owner wanted the road trip to read like an aerial view: small trees, a wide stretch of road and
forest on screen. The stretch mode is now **`canvas_items`** (still integer scale over the
640×360 base), so the UI keeps its big pixels while the world can be drawn at the screen's own
resolution. On layer 1 the camera zooms out (`StateMap.world_zoom`) so that one texel is a whole
number of screen pixels, about half a UI pixel: zoom 1/2 at 720p and 1440p, 1/3 at 1080p. Texels
stay square and never split. The streamed forest keeps two chunks around the truck in each
direction to fill the wider view; town names keep UI size and draw above the trees. The diorama
keeps zoom 1 (same size as before; its rotation is now drawn at screen resolution).
