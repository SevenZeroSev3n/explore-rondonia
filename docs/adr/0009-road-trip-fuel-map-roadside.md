# ADR 0009 — Road trip: fuel, map, speedometer and a livelier roadside

- Status: accepted
- Date: 2026-11-24
- Amends: ADR 0008 (a soft setback is now allowed), CONTEXT.md MVP scope (fuel and map are in)

## Context

After the jump to 640×360 (ADR 0005 update) the owner asked for the drive to feel more like a
real road trip on BR-364: a speedometer in km/h, a fuel cycle with petrol stations along the way,
a map to see where you are and how far is left, a wider road, more and more varied trees, grass,
fences and animals, and no plain flat shapes. Three of these touch the MVP's "out" list: fail
states, economy, and traffic/NPCs. The owner chose:

- **Fuel:** when the tank runs dry the truck stops and is **towed** to a petrol station.
- **Animals:** **static scenery**, planted like the trees.
- **Map:** both a **minimap** in the corner and a **full map** on M.

## Decision

**Fuel.** The tank holds **250 km** of real road distance. Fuel burns with distance driven (on or
off the road), not with time, so a parked truck never runs dry. Petrol stations stand at the ten
towns on BR-364 in the map data (every one of them has real stations, so the "every place is
real" promise of the tutorial holds); the longest gap between towns is 183 km, inside one tank.
Stopping next to a station fills the tank, free (no economy). An empty tank stops the truck; after
a short message a tow truck takes it to the **nearest station along the road** with a full tank.
This is a **soft setback, not a game over**: nothing collected is lost, there is no money and no
timer. It amends ADR 0008's "no fail states" wording only in this sense.

**Speed and distance.** The speedometer shows a nominal **km/h**: top speed on asphalt reads
100 km/h and the other surfaces scale with it (dirt 60, off-road 35). Distances in the minimap
and the full map are **real kilometres along BR-364** (the map is compressed, ADR 0003, but the
numbers are the real ones a traveller would see on road signs).

**Map.** A minimap in the top-right corner shows the state outline, BR-364, the stamp cities and
the truck, with the distance to the next town and to Porto Velho. M opens a full map (pauses the
game like the passport) with rivers, every town, the petrol stations and the player.

**Roadside.** The asphalt is wider (half-width 17 → 22 px). The ground gets a tiled pixel texture
and small flat decals (grass tufts, flowers, stones) instead of a flat colour. Trees get two new
real species common in Rondônia: **babaçu** (the palm that dominates cleared pastures) and
**sumaúma** (the giant of the forest), plus a slight per-tree tint so neighbours differ. Pastures
along the road get **barbed-wire fences** and **Nelore cattle**; riverbanks get **capybaras**.
Animals are sprite stacks that stand still: no movement, no AI, so they stay scenery and not NPCs.

**Art.** Every new sprite stack (petrol station, cattle, capybara, babaçu, sumaúma) starts as a
code-drawn placeholder and gets a four-view prompt in `art/views/04-road-trip.md` for the owner
to generate elsewhere (ADR 0004). Ground texture, decals and fence posts are drawn in code.

## Consequences

- New pure logic, tested with GUT: fuel tank, road progress (km along BR-364), station lookup.
- New input action `map` (M / gamepad Back).
- CONTEXT.md lists fuel, map and static animals as in scope; moving animals, traffic and money
  stay out.
