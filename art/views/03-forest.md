# Prompts: the forest of Rondônia

Read `00-workflow.md` first. The state map is covered by thousands of these, mixed by habitat,
so they are the bulk of what the player sees. Each species is a real tree of Rondônia, placed where
it actually grows (`game/scripts/world/forest.gd`):

| Habitat | What grows there | Why |
|---|---|---|
| **Forest** (away from the road) | castanheira, seringueira, açaí, embaúba, rare ipê and buriti, shrubs underneath | mixed terra-firme rainforest; dense, with groves and clearings |
| **Riverside** (near rivers) | buriti, açaí, some seringueira | buriti and açaí palms line wet ground and rivers |
| **Pasture** (the cleared belt along BR-364) | babaçu palms, embaúbas, lone castanheiras, a few ipês | cattle pasture; castanheiras are protected by law, so they are often left standing alone after clearing — a typical Rondônia roadside sight; babaçu takes over cleared land |

Babaçu and sumaúma (added by ADR 0009) have their prompts in `04-road-trip.md`.

Trees are symmetric, so their SIDE, FRONT and BACK views can be the same drawing; that is
correct and makes generation easier. What matters most is the **TOP view** (the crown seen from
above), because that is most of what the player sees from the camera angle.

General tips for trees:

- Ask for a **clear gap between crown and ground** in the side views when the species has a bare
  trunk: that gap is what makes the trunk visible in the game.
- Ask for **chunky, clumped foliage** with 3–4 shades of one green, not individual leaves.
- Trunks thinner than ~1/12 of the tree width disappear; ask for "a sturdy visible trunk".

---

## Castanheira (Brazil-nut tree, *Bertholletia excelsa*) — `castanheira_views.png`

**Target box:** 32 × 32 × 35 voxels. The tallest tree of the forest.

**Look:** an emergent giant: a very tall, straight, **bare grey cylindrical trunk** for most of
its height, branches only near the top, then a **wide, flattish, umbrella-like dense crown**,
dark green.

**Palette:** trunk `#7a6a5a` / `#5a4a3c`, crown `#2e5c34` / `#3a7040` / `#4c8644` / `#629c4e`.

> Pixel art orthographic reference sheet of a Brazil-nut tree (castanheira): a very tall straight
> bare grey trunk with no branches for most of its height, and at the top a wide, flat,
> umbrella-shaped dense dark green crown of clumped foliage, arranged in a 2x2 grid on a flat pure
> white background. Top-left cell: top view seen straight from above (the round crown). Top-right
> cell: side view. Bottom-left cell: front view. Bottom-right cell: back view. All four views at
> exactly the same scale, centred, orthographic, no perspective, no ground, no grass, no roots,
> no shadows, no text, flat colours, 4 shades of green, sturdy visible trunk.

---

## Seringueira (rubber tree, *Hevea brasiliensis*) — `seringueira_views.png`

**Target box:** 27 × 27 × 27 voxels. Medium tree.

**Look:** a medium tree with a **light grey-brown smooth trunk** and a **dense, rounded,
egg-shaped crown** of glossy mid-green leaves starting about a third of the way up. Rondônia's
rubber history (the *seringueiros*) makes it a meaningful species.

**Palette:** trunk `#968c7c`, crown `#2e5c34` / `#3a7040` / `#4c8644`.

> Pixel art orthographic reference sheet of a rubber tree (seringueira): a smooth light grey-brown
> trunk and a dense rounded egg-shaped crown of glossy mid-green foliage starting a third of the
> way up, arranged in a 2x2 grid on a flat pure white background. Top-left cell: top view seen
> straight from above. Top-right cell: side view. Bottom-left cell: front view. Bottom-right
> cell: back view. All four views at exactly the same scale, centred, orthographic, no
> perspective, no ground, no shadows, no text, flat colours, 3 shades of green, sturdy visible
> trunk.

---

## Açaí palm (*Euterpe precatoria*) — `acai_views.png`

**Target box:** 16 × 16 × 32 voxels. Thin and tall.

**Look:** a **very slender, straight grey-green trunk** (one stem) and, at the very top, a small
crown of **arching, drooping feather-like fronds** radiating out, with a hint of dark purple
fruit bunches under the crown.

**Palette:** trunk `#787c68`, fronds `#3a6234` / `#4e7a3c` / `#689246`, fruit `#3c2440`.

> Pixel art orthographic reference sheet of an açaí palm: a very slender straight grey-green
> single trunk and, at the very top, a small crown of arching drooping feather-like palm fronds
> radiating in all directions, with small dark purple fruit bunches just under the crown,
> arranged in a 2x2 grid on a flat pure white background. Top-left cell: top view seen straight
> from above (a star of fronds). Top-right cell: side view. Bottom-left cell: front view.
> Bottom-right cell: back view. All four views at exactly the same scale, centred,
> orthographic, no perspective, no ground, no shadows, no text, flat colours, chunky fronds,
> trunk at least 2 pixels wide.

**Note:** this is the thinnest object; ask for chunky fronds and a 2-pixel trunk or the carver
loses them.

---

## Buriti palm (*Mauritia flexuosa*) — `buriti_views.png`

**Target box:** 24 × 24 × 32 voxels.

**Look:** a **thick, straight, columnar brown-grey trunk** with ring marks and a **round crown of
large fan-shaped (palmate) leaves**, spiky at the edges, mid green with a little yellow-green.
Grows in wet ground along rivers.

**Palette:** trunk `#70604c`, leaves `#3a6234` / `#4e7a3c` / `#7a9a4a`.

> Pixel art orthographic reference sheet of a buriti palm: a thick straight columnar brown-grey
> trunk with faint rings and, at the top, a round crown of large fan-shaped palm leaves with spiky
> edges, mid green with some yellow-green, arranged in a 2x2 grid on a flat pure white background.
> Top-left cell: top view seen straight from above (a round spiky crown). Top-right cell: side
> view. Bottom-left cell: front view. Bottom-right cell: back view. All four views at exactly the
> same scale, centred, orthographic, no perspective, no ground, no water, no shadows, no text, flat
> colours, limited palette.

---

## Ipê-amarelo in bloom (*Handroanthus*) — `ipe_views.png`

**Target box:** 27 × 27 × 27 voxels. A rare accent in the forest.

**Look:** in the dry season (around July–September) the ipê drops its leaves and is covered in
**bright yellow flowers**: a dark twisting trunk and branches under an airy, rounded crown of
**vivid yellow blossom clusters**, almost no green.

**Palette:** trunk `#4e3424`, flowers `#c99a1e` / `#e8c33a` / `#f2d65a`.

> Pixel art orthographic reference sheet of a yellow ipê tree in full bloom with no leaves: a dark
> brown trunk with a few twisting branches, under an airy rounded crown made of vivid bright
> yellow flower clusters, arranged in a 2x2 grid on a flat pure white background. Top-left cell:
> top view seen straight from above. Top-right cell: side view. Bottom-left cell: front view.
> Bottom-right cell: back view. All four views at exactly the same scale, centred, orthographic,
> no perspective, no ground, no fallen flowers, no shadows, no text, flat colours, 3 shades of
> yellow, sturdy visible trunk.

---

## Embaúba (*Cecropia*) — `embauba_views.png`

**Target box:** 21 × 21 × 24 voxels.

**Look:** a pioneer tree of clearings and roadsides: a **thin, pale, almost white segmented
trunk**, a few branches rising like a **candelabra**, each ending in a cluster of **huge
umbrella-shaped leaves**, green on top and **silvery-white underneath**. From above: a few
separate leaf clusters, not one solid crown.

**Palette:** trunk `#d6d0c0`, leaves `#6f8f74` / `#9fb8a0` / `#c8d6c8`.

> Pixel art orthographic reference sheet of an embaúba (Cecropia) tree: a thin pale almost white
> segmented trunk, a few branches rising like a candelabra, each ending in a cluster of huge
> umbrella-shaped leaves that are green on top and silvery white underneath, arranged in a 2x2
> grid on a flat light grey (#f0f0f0) background. Top-left cell: top view seen straight from
> above (several separate leaf clusters). Top-right cell: side view. Bottom-left cell: front
> view. Bottom-right cell: back view. All four views at exactly the same scale, centred,
> orthographic, no perspective, no ground, no shadows, no text, flat colours, limited palette,
> trunk at least 2 pixels wide.

**Note:** light grey background because the trunk is nearly white.

---

## Undergrowth shrub — `shrub_views.png`

**Target box:** 13 × 13 × 8 voxels. Small, low, everywhere under the trees.

**Look:** a low, round, dense bush of dark and mid greens with a few lighter leaves on top; no
visible trunk.

**Palette:** `#284e2c` / `#386234` / `#48743a`.

> Pixel art orthographic reference sheet of a small low round dense tropical bush with clumped dark
> and mid green leaves and a few lighter leaves on top, no visible trunk, wider than tall, arranged
> in a 2x2 grid on a flat pure white background. Top-left cell: top view seen straight from above.
> Top-right cell: side view. Bottom-left cell: front view. Bottom-right cell: back view. All four
> views at exactly the same scale, centred, orthographic, no perspective, no ground, no shadows, no
> text, flat colours, 3 shades of green.

---

## Checking the forest in the game

After building (`python3 tools/build_stacks.py`), drive three places, or ask Claude for
screenshots of them:

1. **Vilhena start / along BR-364:** pasture with scattered embaúbas and lone castanheiras.
2. **Off-road between Jaru and Ariquemes:** dense mixed forest with clearings and yellow ipês.
3. **The Machado river near Ji-Paraná:** buriti and açaí palms along the water.

Every species should be recognisable by silhouette and colour alone: the flat crown on a tall
pole (castanheira), the round blob (seringueira), the green star (açaí), the spiky ball (buriti),
yellow (ipê), silvery clusters (embaúba).
