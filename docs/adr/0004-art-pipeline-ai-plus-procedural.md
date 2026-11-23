# ADR 0004 — Art pipeline: AI 4-view sheets + procedural

- Status: accepted
- Date: 2026-11-23

## Context

The state map needs thousands of trees, houses and terrain pieces, plus a handful of hand-picked
landmarks. Nobody on the project is a voxel artist. AI generation from four orthographic views is
fast but cannot express holes or overhangs (locomotive wheels, open cab, arcades).

## Decision

- **Procedural by code:** vegetation, generic buildings, terrain, roadside props.
- **AI 4-view sheets** for vehicles and landmarks, generated with any image generator (first
  attempts with the generator available to the agent; SpriteCook as fallback), approved and
  touched up by the owner, then cut into slice sheets by a `tools/` script.
- The MVP **accepts the simplified silhouettes** of AI landmarks. Any asset can later be replaced
  by a MagicaVoxel version without game changes, because the slice-sheet format is the contract.

## Update (2026-11-23)

The agent's only image generator (Figma AI) spends paid AI credits, which the owner's Starter
plan with a View seat may not include; the owner chose to generate the four-view sheets
elsewhere from the prompts in `art/views/README.md`.
`tools/views_to_slices.py` carves them (visual hull: a voxel stays where the top, side and
front/back silhouettes all see the object) into the same sizes as the placeholders.

## Consequences

- Source art lives in `art/`; only final slice sheets live in `game/assets/stacks/<name>/`.
- The slicer is tested with `pytest`.
