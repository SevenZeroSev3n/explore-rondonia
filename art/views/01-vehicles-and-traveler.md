# Prompts: the pickup truck and the traveler

Read `00-workflow.md` first: layout, checklist and fixes are there. Each prompt below is
complete; paste it as is.

---

## Pickup truck — `truck_views.png`

**In the game:** the player's vehicle on the state map, always on screen, rotating freely as you
drive BR-364. It is the most-seen object in the game: worth the extra tries.

**Target box:** 27 wide × 48 long × 12 tall voxels (long and low).

**What it should look like:** a generic, modern compact pickup like the ones on every road in
Rondônia: white body, short hood, double cab with dark windows, an **open cargo bed** at the back,
black tyres with a little red-dirt dust. No brand, no logo, no number plate text.

**Palette (suggested):** body white `#e8e4d8` with grey shade `#b8b2a4`, windows `#4e7084`,
bumpers and tyres `#3a363c` / `#222024`, headlights `#faecaa`, tail lights `#c43028`, red dust
`#9c4a2f`.

**Prompt:**

> Pixel art orthographic reference sheet of a generic white compact double-cab pickup truck with
> no brand and no logos, a short hood, dark tinted windows, an open empty cargo bed at the back,
> black tyres lightly dusted with red dirt, arranged in a 2x2 grid on a flat plain light grey
> (#f0f0f0) background. Top-left cell: top view seen straight from above, the front of the truck
> pointing up. Top-right cell: side view of the truck's right side, the front pointing left.
> Bottom-left cell: front view. Bottom-right cell: back view. All four views at exactly the same
> scale, centred in their cells, orthographic, no perspective, no shadows, no ground, no road, no
> text, no labels, flat colours, limited palette, crisp dark outline around the truck.

**Notes:**

- Light grey background instead of white, so the white truck keeps a clear edge.
- In TOP, the hood is at the **top** of the cell and the cargo bed at the bottom.
- The open bed will come out filled (four views cannot carve it); its floor colour still shows on
  top, which reads well in game.
- Common failure: generators draw the side view in 3/4. Insist on "orthographic, flat side
  elevation, like a blueprint".

---

## Traveler on foot — `traveler_views.png`

**In the game:** the player walking inside dioramas (the Madeira-Mamoré railway yard). Tiny on
screen, so it must read by colour and silhouette alone.

**Target box:** 11 wide × 11 long × 19 tall voxels (a person, about 11 px wide on screen).

**What it should look like:** a friendly traveler: straw hat with a wide brim, orange or red
shirt, blue trousers, brown shoes, a small backpack on the back. Arms down along the body,
standing straight (an "A-pose" or arms at the sides), facing forward.

**Palette (suggested):** skin `#c48c64`, shirt `#d65c34`, trousers `#38466a`, hat `#dec88c`,
backpack `#6b4a2e`.

**Prompt:**

> Pixel art orthographic reference sheet of a small cheerful traveler standing straight with arms
> at the sides, wearing a wide straw hat, an orange short-sleeved shirt, blue trousers, brown
> shoes and a small brown backpack, chunky simple proportions, arranged in a 2x2 grid on a flat
> pure white background. Top-left cell: top view seen straight from above (mostly the hat brim),
> the face pointing up. Top-right cell: side view of the right side, facing left. Bottom-left
> cell: front view. Bottom-right cell: back view showing the backpack. All four views at exactly
> the same scale, centred, orthographic, no perspective, no shadows, no ground, no text, flat
> colours, limited palette.

**Notes:**

- At 11×11×19, only the big colour blocks survive: hat on top, shirt, trousers. Do not spend tries
  on faces.
- The TOP view must show the hat brim round and **bigger than the body**, otherwise the hat gets
  carved to the body's width.
- The facing matters: in TOP, the face (front of the hat brim) points up.
