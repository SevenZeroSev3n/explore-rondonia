# ADR 0003 — Real geodata through a Python pipeline

- Status: accepted
- Date: 2026-11-23

## Context

The state shape and the curves of the highways should be recognizable, and adding BR-425, BR-429
etc. later should be cheap. Hand-drawing over a reference map does not scale and drifts.

## Decision

A pipeline in `tools/` reads **OpenStreetMap** (highways, rivers) and **IBGE** (state border,
municipal seats), then projects, simplifies and **uniformly scales** them into JSON under
`data/geo/` that Godot reads. The scale is one parameter, tuned so driving BR-364 end to end at
cruise speed takes **~8 minutes**. Uniform scale preserves real proportions between stretches.
Raw downloads go to `data/geo/raw/` (git-ignored); generated JSON is committed.

## Consequences

- Lat/long → game-world conversion is the main source of silent bugs; it is covered by `pytest`.
- OSM requires ODbL attribution in the credits.
- Roadside procedural rules take a land-cover input, so MapBiomas can replace the simple rules
  later without touching the rest.
