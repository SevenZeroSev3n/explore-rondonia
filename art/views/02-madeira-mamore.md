# Prompts: the Madeira-Mamoré Railway landmarks (Porto Velho)

Read `00-workflow.md` first. These three objects are the **photographable landmarks** of the
Madeira-Mamoré diorama, so players will walk around them and look at them from every side.
Their place texts (with sources) are in `game/data/places/efmm_*.json`.

Historical context for the generator (and for you to judge the result): the railway was built
between 1907 and 1912 to link Porto Velho to Guajará-Mirim; its yard, sheds and locomotives are a
listed heritage site. The water towers were made by the Chicago Bridge & Iron Works and installed
between 1910 and 1912. Aim for that period: early 1900s, steam, riveted iron, brick.

Do **not** copy a specific photo or a specific museum locomotive number; draw an original object
in that style.

---

## Steam locomotive — `locomotive_views.png`

> **Now built from `art/vox/locomotive.vox`** (MagicaVoxel, see `art/vox/README.md`), which wins
> over a views sheet in `tools/build_stacks.py`. The prompt below stays as a fallback.

**In the game:** sits on the rails in the railway yard; photographed from the south (its right
side).

**Target box:** 24 wide × 53 long × 23 tall voxels.

**What it should look like:** a small early-1900s narrow-gauge steam locomotive: long black
cylindrical boiler at the front, a tall flared smokestack near the front, a steam dome on top of
the boiler, a cowcatcher at the very front, four pairs of red-spoked driving wheels, and the
driver's cab at the back with a roof. Black iron with red trim and a few brass details.

**Palette (suggested):** iron `#28282e` / `#46464e`, red trim `#962822`, brass `#b8923a`, cab roof
`#3a3a40`.

**Prompt:**

> Pixel art orthographic reference sheet of an early-1900s small narrow-gauge steam locomotive in
> black iron with red trim and brass details: a long cylindrical boiler at the front, a tall
> flared smokestack near the front, a round steam dome on top of the boiler, a cowcatcher at the
> very front, red-spoked driving wheels along both sides, and a roofed driver's cab at the back,
> arranged in a 2x2 grid on a flat pure white background. Top-left cell: top view seen straight
> from above, the front (smokestack end) pointing up. Top-right cell: side view of the right side,
> the front pointing left. Bottom-left cell: front view (cowcatcher and boiler face). Bottom-right
> cell: back view (cab rear). All four views at exactly the same scale, centred, orthographic, no
> perspective, no rails, no ground, no smoke, no shadows, no text, flat colours, limited palette.

**Notes:**

- "No rails, no smoke": both would be carved into the model as solid blocks.
- The open cab will come out solid (ADR 0004). Fine for now.
- The smokestack must be **thick** enough to survive (at least 3–4 voxels wide at game size).

---

## Railway workshop shed — `shed_views.png`

**In the game:** a long building next to the rails, between the tracks and the river; its door
faces the visitor.

**Target box:** 85 wide × 48 deep × 27 tall voxels (wide and long, so the **front is the long
side**).

**What it should look like:** an early-1900s railway workshop (oficina / galpão): long
rectangular red-orange brick walls, a row of tall arched windows, a big wooden double door in
the middle of the long front wall, and a grey corrugated-metal **gable roof whose ridge runs
along the long side**.

**Palette (suggested):** brick `#aa6846` / `#885038`, window frames `#e8e0cc`, wood door
`#6b4a2e`, roof `#808488` / `#686c70`.

**Prompt:**

> Pixel art orthographic reference sheet of a long early-1900s brick railway workshop building:
> red-orange brick walls, a row of tall arched windows, a large wooden double door in the middle
> of the long front wall, and a grey corrugated metal gable roof whose ridge runs along the
> building's length, arranged in a 2x2 grid on a flat pure white background. Top-left cell: top
> view seen straight from above showing the roof, the long front wall (with the door) facing up.
> Top-right cell: side view of the right gable end (the triangular end wall), the front facing
> left. Bottom-left cell: front view of the long front wall with the big door. Bottom-right cell:
> back view of the long back wall. All four views at exactly the same scale, centred,
> orthographic, no perspective, no ground, no shadows, no people, no text, flat colours, limited
> palette.

**Notes:**

- The orientation is the one that trips generators: the **front is the long wall with the door**.
  In TOP the building is wider than tall, with the door side at the top.
- The SIDE view is the narrow **gable end**: a rectangle with a triangle on top. That triangle is
  what gives the roof its shape when carved.
- The door will be carved as wall (no holes); its colour still shows on the front face.

---

## Water tower (one of the Três Caixas d'Água) — `water_tower_views.png`

**In the game:** the diorama places **three copies** of this tower in a triangle, as in Porto
Velho's "Três Marias". Photographed from the east.

**Target box:** 21 wide × 21 long × 48 tall voxels (tall and slender).

**What it should look like:** an early-1900s riveted steel water tower: a cylindrical tank with a
shallow conical roof, sitting on **four tall straight steel legs** joined by horizontal rings and
X-shaped cross bracing, a small ladder up one leg. Silver-grey steel.

**Palette (suggested):** tank `#b0b6ba` / `#8c9296`, legs and bracing `#46464e`, roof `#7c8286`.

**Prompt:**

> Pixel art orthographic reference sheet of an early-1900s riveted steel water tower: a
> cylindrical silver-grey tank with a shallow conical roof on top, standing on four tall straight
> dark steel legs joined by horizontal rings and X-shaped cross bracing, with a thin ladder up one
> leg, arranged in a 2x2 grid on a flat pure white background. Top-left cell: top view seen
> straight from above (the round roof covering the legs). Top-right cell: side view. Bottom-left
> cell: front view. Bottom-right cell: back view. All four views at exactly the same scale,
> centred, orthographic, no perspective, no ground, no shadows, no text, flat colours, limited
> palette, chunky legs.

**Notes:**

- The tower is symmetric: SIDE, FRONT and BACK can look identical; that is correct.
- Ask for **chunky** legs: at 16 voxels wide, legs thinner than one voxel disappear, and the tank
  ends up floating.
- The X bracing will mostly fill in between the legs from the side; that reads fine at game size.
