# Prompts: the road trip — petrol station, new trees, animals

Read `00-workflow.md` first. These are the sprite stacks added by ADR 0009 (fuel, a livelier
roadside). Until you deliver an image, each one is a code-drawn placeholder; save the generated
sheet as `art/views/<name>_views.png` and run `python3 tools/build_stacks.py --only <name>`.

| Name | What | Where it appears |
|---|---|---|
| `fuel_station` | roadside petrol station | one beside BR-364 at each of the 10 towns |
| `babacu` | babaçu palm | everywhere in the pastures along the road, some in the forest |
| `sumauma` | sumaúma (kapok), the forest giant | rare, in the forest and by rivers |
| `cattle` | Nelore cow | herds in the pastures, behind the fences |
| `capybara` | capivara | small groups on the riverbanks |

Fence posts, wire, grass tufts, flowers and stones are drawn in code (`tools/make_ground.py`,
`tools/make_placeholder_stacks.py`); they need no image.

Tips for this batch:

- **Animals are tiny in the game** (a cow is 8 voxels wide). Only big colour blocks survive: ask
  for chunky shapes, flat colours and a clear silhouette. Legs must be **thick** (at least 1/8 of
  the body length each) or they vanish.
- Animals **face the front**: TOP view with the head pointing **up**, SIDE view with the head
  pointing **left** (right side of the animal). Getting this wrong makes them walk backwards.
- Nothing on the ground: no grass patch under the animal, no shadow.

---

## Petrol station (posto de combustível) — `fuel_station_views.png`

**Target box:** 64 wide × 48 deep × 24 tall voxels. Its **front faces the road**: the pumps and
the canopy are at the front, the small shop at the back.

**Look:** a small Brazilian roadside petrol station of a generic, **unbranded** kind (no real
company names or logos): a flat white **canopy** on four columns over **two pump islands** with
red pumps, a light-grey concrete forecourt, a small single-storey **shop/convenience store** with
a door and windows behind the canopy, and a tall **price sign** pole at one front corner with a
plain green-and-white board (no text). Clean, slightly dusty, Amazon-highway feel.

**Palette:** canopy `#e8e8e2` with a green band `#28784a`, pumps `#d23c2e`, forecourt `#969696`,
shop walls `#c8a07a`, shop roof `#686c70`, sign pole `#46464e`.

> Pixel art orthographic reference sheet of a small generic unbranded roadside petrol station: a
> flat white canopy with a green band on four columns over two islands of red fuel pumps, a light
> grey concrete forecourt, a small single-storey shop with a door and windows behind the canopy,
> and a tall sign pole with a plain green and white board with no text, arranged in a 2x2 grid on
> a flat pure white background. Top-left cell: top view seen straight from above, the canopy and
> pumps (the front, facing the road) pointing up. Top-right cell: side view of the right side,
> the front pointing left. Bottom-left cell: front view (canopy and pumps). Bottom-right cell:
> back view (the shop). All four views at exactly the same scale, centred, orthographic, no
> perspective, no cars, no people, no road, no ground beyond the forecourt, no shadows, no text,
> no logos, flat colours, limited palette.

**Notes:**

- "No logos, no text": brands are not allowed (ADR 0004 licence rules) and text would be carved
  into noise.
- The space under the canopy will come out **solid** (four views cannot carve it). Acceptable;
  a MagicaVoxel model can open it later, like the locomotive.

---

## Babaçu palm (*Attalea speciosa*) — `babacu_views.png`

**Target box:** 24 × 24 × 32 voxels.

**Look:** the palm that takes over Rondônia's cleared pastures: a **straight, medium-thick grey
trunk** with a rough texture, topped by a **big fountain of long, stiff, feather-shaped fronds**
that arch up and out (not drooping like a coconut palm), deep green with lighter tips. Often the
lower part of the crown keeps a few dry brown old fronds.

**Palette:** trunk `#766858` / `#5e5246`, fronds `#46743a` / `#5c8c3e` / `#7aa24e`, dry frond
`#8a7048`.

> Pixel art orthographic reference sheet of a babaçu palm tree: a straight medium-thick rough grey
> trunk and a large fountain of long stiff feather-shaped fronds arching upward and outward, deep
> green with lighter tips and a couple of dry brown fronds at the base of the crown, arranged in a
> 2x2 grid on a flat pure white background. Top-left cell: top view seen straight from above (the
> star of fronds). Top-right cell: side view. Bottom-left cell: front view. Bottom-right cell:
> back view. All four views at exactly the same scale, centred, orthographic, no perspective, no
> ground, no grass, no shadows, no text, flat colours, chunky thick fronds, sturdy visible trunk.

---

## Sumaúma (kapok, *Ceiba pentandra*) — `sumauma_views.png`

**Target box:** 40 × 40 × 48 voxels. The biggest object in the forest: it should tower over
every other tree.

**Look:** the giant of the Amazon: huge **buttress roots** fanning out like walls at the base, a
very tall, thick, **smooth pale grey trunk**, and far above a **very wide, flat, spreading crown**
of horizontal branches with clumped mid-green foliage, wider than it is tall.

**Palette:** trunk and roots `#a09888` / `#7e7668`, crown `#2e5c34` / `#3a7040` / `#4c8644` /
`#629c4e`.

> Pixel art orthographic reference sheet of a giant kapok tree (sumaúma): large buttress roots
> fanning out like thin walls at the base, a very tall thick smooth pale grey trunk, and at the top
> a very wide flat spreading crown of horizontal branches with clumped mid-green foliage, arranged
> in a 2x2 grid on a flat pure white background. Top-left cell: top view seen straight from above
> (the wide round crown). Top-right cell: side view. Bottom-left cell: front view. Bottom-right
> cell: back view. All four views at exactly the same scale, centred, orthographic, no
> perspective, no ground, no grass, no shadows, no text, flat colours, 4 shades of green, thick
> visible trunk, buttress roots clearly visible below the crown.

---

## Nelore cow (gado Nelore) — `cattle_views.png`

**Target box:** 8 wide × 20 long × 13 tall voxels.

**Look:** the white cattle of Rondônia's pastures: a **Nelore (zebu) cow**, **white to very light
grey**, with the breed's **big hump** over the shoulders, a loose dewlap under the neck, long
droopy ears, short dark horns, a dark muzzle and dark hooves. Standing, calm.

**Palette:** body `#e2e0d8` / `#c4c0b8`, hump and shading `#b0aca4`, muzzle, horns and hooves
`#3c3834`.

> Pixel art orthographic reference sheet of a white Nelore zebu cow with a large hump over the
> shoulders, a loose dewlap, long droopy ears, short dark horns, a dark muzzle and dark hooves,
> standing calmly, chunky simple shapes with thick legs, arranged in a 2x2 grid on a flat plain
> light blue-grey background (#cfd8e0). Top-left cell: top view seen straight from above, the head
> pointing up. Top-right cell: side view of the right side, the head pointing left. Bottom-left
> cell: front view (the face). Bottom-right cell: back view (the tail). All four views at exactly
> the same scale, centred, orthographic, no perspective, no grass, no ground, no shadows, no
> text, flat colours, dark outline.

**Note:** the background is **light blue-grey on purpose** (rule 6 of `00-workflow.md`): a white
cow on white would lose its shape. If it still comes out thin, set a lower `tolerance` for
`cattle` in `build_stacks.VIEW_OPTIONS`, as for the white truck.

---

## Capybara (capivara) — `capybara_views.png`

**Target box:** 6 wide × 11 long × 6 tall voxels. Very small.

**Look:** a **capybara**: a big barrel-shaped rodent, **reddish-brown** fur, a large blunt
square head with small ears and eyes on top, no visible tail, short thick legs. Resting calmly.

**Palette:** fur `#84603f` / `#684a32`, face and feet `#4e3a28`.

> Pixel art orthographic reference sheet of a capybara: a barrel-shaped reddish-brown rodent with
> a large blunt square head, small ears, short thick legs and no tail, standing calmly, very
> chunky simple shapes, arranged in a 2x2 grid on a flat pure white background. Top-left cell: top
> view seen straight from above, the head pointing up. Top-right cell: side view of the right
> side, the head pointing left. Bottom-left cell: front view (the face). Bottom-right cell: back
> view. All four views at exactly the same scale, centred, orthographic, no perspective, no
> grass, no water, no ground, no shadows, no text, flat colours, dark outline.
