# ADR 0003 — Real geodata through a Python pipeline

- Status: accepted
- Date: 2026-11-23

## Context

The state shape and the curves of the highways should be recognizable, and adding BR-425, BR-429
etc. later should be cheap. Hand-drawing over a reference map does not scale and drifts.

## Decision

A pipeline in `tools/` reads **OpenStreetMap** (highways, rivers, town positions) and **IBGE**
(state border), then projects, simplifies and **uniformly scales** them into JSON under
`game/data/geo/` that Godot reads (inside the Godot project so the web export packs it). The
scale is one parameter, tuned so driving BR-364 end to end at cruise speed takes **~8 minutes**. Uniform scale preserves real proportions between stretches.
Raw downloads go to `tools/cache/` (git-ignored); generated JSON is committed. The road is the
shortest path over the OSM BR-364 ways between the towns nearest each end, inside the largest
connected component (OSM leaves small detached fragments).

## Consequences

- Lat/long → game-world conversion is the main source of silent bugs; it is covered by `pytest`.
- OSM requires ODbL attribution in the credits.
- Roadside procedural rules take a land-cover input, so MapBiomas can replace the simple rules
  later without touching the rest.
