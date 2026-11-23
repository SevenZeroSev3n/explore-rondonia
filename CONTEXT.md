# Explore Rondônia — context

## What it is

A small **cozy game** with an educational bent: drive across Rondônia, stamp a tourist passport and
photograph real landmarks to unlock their real photos. Faithful in spirit, not a practical,
always-up-to-date travel guide. Portfolio piece, released on itch.io. Large expected foreign audience,
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
| **Passport** | The player's goal: city stamps + valid photos of landmarks and secrets. |
| **Stamp** | Earned by reaching a city. |
| **Photo spot** | A registered landmark or secret; a photo counts when it is fully in frame, close enough and inside the spot's angle window. |
| **Angle window** | The range of camera headings (about ±30°) from which a photo spot counts. |
| **Secret** | A real place off or beside BR-364 (viewpoint, waterfall, bridge, river beach) found by exploring. |
| **Traveler** | The small on-foot character used in dioramas. |

## MVP scope

In: passport loop (ADR 0008) — start in Vilhena with a one-screen tutorial, end when 4 stamps,
4 Madeira-Mamoré photos and 3 real roadside secrets are collected (30–45 min); photo mode on
both layers; walking on foot in the diorama; potholes and dirt slow the vehicle (no game over);
BR-364 from Vilhena to Porto Velho; cities Vilhena, Ji-Paraná, Ariquemes, Porto Velho
(markers + sheet); one diorama — Madeira-Mamoré Railway (locomotive, railway sheds, Três Caixas
d'Água, Madeira river bank); one generic pickup truck; off-road allowed but slow, state border is
the limit; procedural roadside from simple rules plus real rivers and bridges; ambient track and
engine sound; local save of visited cities; pt-BR + English (browser locale, PT/EN toggle);
credits screen.

Out: day/night, weather, traffic/NPCs, story missions, photo scoring/stars, economy/freight,
fail states, cloud save, touch/mobile, other highways,
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
7. Public GitHub repo `explore-rondonia`, Actions → GitHub Pages (dev build), itch.io for
   releases; pytest + GUT for pure logic.
8. It's a game: cozy passport-and-photo loop, no game over, real places as the reward.

## Language

Repo artifacts (code, docs, ADRs, commits) are in English. Player-facing text lives in
`game/data/i18n/` and `game/data/places/` in pt-BR and English. Local proper names stay in Portuguese
("Três Caixas d'Água"), with a short English gloss.
