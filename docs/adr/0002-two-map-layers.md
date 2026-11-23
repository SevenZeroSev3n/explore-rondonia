# ADR 0002 — Two map layers, hybrid travel

- Status: accepted
- Date: 2026-11-23
- Amended by: ADR 0008 (game loop; missions-like goals are now in scope)

## Context

Rondônia covers ~238,000 km²; BR-364 alone crosses the state for well over 700 km. A real-scale
pixel-art world would be empty and tiring to drive. Driving is still the core charm of sprite
stacking (the rotating vehicle).

## Decision

- **Layer 1 — state map:** the whole state, stylized and uniformly compressed, **north-up fixed
  camera**. Highways are driven here. Roadside is procedural.
- **Layer 2 — local area (diorama):** detailed explorable scenes entered from a city, with a
  **rotating camera**.
- **Travel is hybrid:** free driving, autopilot along the road graph, teleport to cities already
  visited (saved locally).
- One generic pickup truck. Leaving the road is allowed but slow; the state border is the limit.
- MVP: BR-364 on layer 1 (Vilhena, Ji-Paraná, Ariquemes, Porto Velho as markers with sheets) and a
  single layer-2 scene, the Madeira-Mamoré Railway in Porto Velho (locomotive, railway sheds, Três
  Caixas d'Água, Madeira river bank).

## Consequences

- Layer transitions are part of the MVP and get tested early.
- Out of the MVP: day/night, weather, traffic/NPCs, story missions, other highways. The passport
  and photo goals of ADR 0008 are in.
