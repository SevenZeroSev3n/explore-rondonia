# Art workflow: from a prompt to the game

How the 12 sprite-stacked objects of Explore Rondônia go from an AI image to the game
(ADR 0004). Read this first; the prompts live in the three files after it.

| File | What it covers |
|---|---|
| `00-workflow.md` | this file: the format, the steps, how to check and fix a result |
| `01-vehicles-and-traveler.md` | the pickup truck and the traveler on foot |
| `02-madeira-mamore.md` | locomotive, railway shed, Três Caixas d'Água |
| `03-forest.md` | the six tree species and the undergrowth shrub |

## 1. What you are making

Every object in the game is a **sprite stack**: a pile of thin horizontal slices drawn on top of
each other, like a CT scan. You do not draw the slices. You make **one image with four flat
views** of the object, and `tools/build_stacks.py` carves those views into slices (a "visual
hull": a voxel stays where the top, side and front/back silhouettes all see the object).

Because of that, the image has to follow a strict layout, or the carving goes wrong.

## 2. The layout every image must follow

One image, split into a **2×2 grid** of equal cells, on a **flat, plain, very light background**
(pure white is best):

```
+-----------------------------+-----------------------------+
| TOP                         | SIDE                        |
| seen straight from above    | the object's RIGHT side     |
| FRONT pointing UP           | FRONT pointing LEFT         |
+-----------------------------+-----------------------------+
| FRONT                       | BACK                        |
| seen from the front         | seen from behind            |
+-----------------------------+-----------------------------+
```

Hard rules:

1. **Orthographic, no perspective.** Flat technical views, like a blueprint. No 3/4 angle.
2. **Same scale in all four cells.** The truck's length in TOP must equal its length in SIDE.
3. **One object per cell, centred, not touching the cell edges.**
4. **Nothing else in the image:** no ground line, no shadow, no text, no labels, no frame, no grid
   lines, no watermark.
5. **Plain background, the same in all four cells.** The carver detects the background from the
   four corners of each cell.
6. **The object's own colours must not be the background colour.** A white truck on white loses
   its outline: give it a light outline or ask for a light-grey background (see 01).
7. **Flat colours, limited palette, no gradients.** The game quantises to 6–16 colours per object
   anyway; soft shading turns into stripes.

## 3. Step by step

1. Pick an object in `01`, `02` or `03` and copy its full prompt.
2. Generate it in any image generator (ChatGPT, Gemini, Midjourney, Firefly, …). Ask for a
   **square image** (1024×1024 or larger).
3. Check the result against the **acceptance checklist** below. If it fails, regenerate (most
   generators need 2–4 tries for a clean four-view sheet) or fix it in an image editor.
4. Save it as **PNG** at `art/views/<name>_views.png`, using the exact `<name>` given in the
   object's section (for example `art/views/truck_views.png`).
5. Build:

   ```bash
   python3 tools/build_stacks.py --only truck
   ```

   Without `--only` it rebuilds everything. Objects without a views file keep their code-drawn
   placeholder, so you can deliver one image at a time.
6. Look at it in the game (or ask Claude to take screenshots). If something looks off, see
   section 5.
7. Commit the PNG in `art/views/` together with the rebuilt sheet in `game/assets/stacks/`.

## 4. Acceptance checklist (before saving)

- [ ] Exactly four views, in the 2×2 order above (TOP top-left, SIDE top-right, FRONT
      bottom-left, BACK bottom-right).
- [ ] TOP: the front of the object points **up**.
- [ ] SIDE: the front points **left**, and it is the **right** side of the object.
- [ ] All four views are the same size, and the object sits well inside each cell.
- [ ] Plain background, no shadows, no ground, no text.
- [ ] No perspective: vertical edges are vertical, nothing recedes.
- [ ] Proportions roughly match the target box given for the object (width × length × height).

## 5. When the result looks wrong in the game

| What you see | Why | Fix |
|---|---|---|
| The object is a solid block or rectangle | The background was not detected (gradient, texture, coloured cells, or a shadow under the object) | Regenerate asking for "flat pure white background, no shadow"; or paint the background white |
| Parts are missing (a roof, a wheel, the crown) | One view does not show that part, so its silhouette carves it away | Make sure every view shows the whole object; regenerate the bad view |
| The object is mirrored or drives sideways | TOP front not pointing up, or SIDE front not pointing right-to-left | Rotate/flip that cell in an editor and save again |
| It is stretched or squashed | Views at different scales | Regenerate asking for "all four views at exactly the same scale" |
| Colours look like stripes | Gradients or soft shading | Ask for "flat colours, no gradients, cel shading" |
| Thin parts disappear (poles, legs, palm fronds) | Thinner than one voxel at game size | Ask for thicker, chunkier parts; pixel-art style helps |
| An opening is filled in (truck bed, cab, door) | Four views cannot carve holes or overhangs | Expected (ADR 0004). A MagicaVoxel model can replace it later |
| Wrong overall size | The target box is fixed by the game | Not a problem with the image: the carver stretches every view to the box |

## 6. Background facts you may need

- Target sizes are a contract with the game code (`tools/build_stacks.py`, `STACKS`). Changing
  one means changing the slice counts in the scenes: ask before doing it.
- The game is pixel art at 480×270 (ADR 0005). A 24-voxel tree is about 24 screen pixels wide, so
  detail smaller than ~1/24 of the object will not survive. Big shapes and clear colours win.
- Licence: original art in this repository is CC BY 4.0 (ADR 0007). Generate only original
  designs: no brands, logos or copies of existing games.
