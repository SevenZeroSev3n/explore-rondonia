# Explore Rondônia — context

## What it is

A portfolio project with an educational bent: a pleasant, faithful-in-spirit way to explore
Rondônia, not a practical, always-up-to-date travel guide. Large expected foreign audience,
so pt-BR and English ship together from the MVP.

## Glossary

| Term | Meaning |
|---|---|
| **Sprite stack** | An object drawn as horizontal pixel-art slices, rendered bottom→top, each lifted 1 px. See `docs/reference/sprite-stacking-guide.md`. |
| **Slice sheet** | One-row PNG of equal slices, ground on the left, art facing up (−Y). The only art format the game loads. |
| **4-view sheet** | Top/side/front/back orthographic drawing (AI-generated) that the pipeline cuts into a slice sheet. Cannot express holes or overhangs. |
| **Layer 1 / state map** | The whole state, stylized and uniformly compressed, north-up camera. Highways are driven here. |
| **Layer 2 / local area (diorama)** | A detailed explorable scene entered from a city on layer 1. Rotating camera. |
| **Place** | A tourist spot or city with a sheet (ficha): bilingual text, real photos, credits. |
| **Ficha / place sheet** | The pixel-framed info panel of a place, with full-resolution (non-pixelated) real photos. |
| **Polo** | One of the 7 official tourism regions of Rondônia (Setur-RO). |
| **Autopilot** | Drives the vehicle along the road graph to a chosen city. |
| **Teleport** | Instant travel to a city already visited (progress saved locally). |

## MVP scope

In: BR-364 from Vilhena to Porto Velho; cities Vilhena, Ji-Paraná, Ariquemes, Porto Velho
(markers + sheet); one diorama — Madeira-Mamoré Railway (locomotive, railway sheds, Três Caixas
d'Água, Madeira river bank); one generic pickup truck; off-road allowed but slow, state border is
the limit; procedural roadside from simple rules plus real rivers and bridges; ambient track and
engine sound; local save of visited cities; pt-BR + English (browser locale, PT/EN toggle);
credits screen.

Out: day/night, weather, traffic/NPCs, missions, cloud save, touch/mobile, other highways,
MapBiomas land cover, Setur-RO material.

## Architecture decisions

See `docs/adr/`. Summary:

1. Godot 4, Compatibility renderer, single-thread web export; web first, desktop bonus.
2. Two map layers; the MVP drives BR-364 on layer 1 and has one layer-2 scene.
3. Geography from real data (OSM + IBGE) through a Python pipeline into game JSON; uniform scale
   tuned so BR-364 end to end takes ~8 minutes of manual driving.
4. Art: AI 4-view sheets sliced by the pipeline + procedural vegetation/buildings/terrain.
5. Look: 480×270 internal resolution, ~32-colour fixed palette, outline on the whole stack.
6. Content as data, bilingual; photos from Wikimedia Commons.
7. Public GitHub repo `explore-rondonia`, Actions → GitHub Pages; pytest + GUT for pure logic.

## Language

Repo artifacts (code, docs, ADRs, commits) are in English. Player-facing text lives in
`data/i18n/` and `data/places/` in pt-BR and English. Local proper names stay in Portuguese
("Três Caixas d'Água"), with a short English gloss.
