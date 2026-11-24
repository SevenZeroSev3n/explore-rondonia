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
elsewhere from the prompts in `art/views/00-workflow.md`.
`tools/views_to_slices.py` carves them (visual hull: a voxel stays where the top, side and
front/back silhouettes all see the object) into the same sizes as the placeholders.

Also on 2026-11-23 the owner asked for a much denser forest with several species. Six real
Rondônia trees (castanheira, seringueira, açaí, buriti, ipê-amarelo, embaúba) and a shrub now
exist as stacks (seven with the shrub); their *art* can come from four-view sheets like any other object
(`art/views/03-forest.md`), while their *placement* stays procedural
(`game/scripts/world/forest.gd`: habitat by distance to road and rivers, noise for groves and
clearings, planting spread over frames).

## Update (2026-11-24): MagicaVoxel models

The owner installed MagicaVoxel (through Wine on Linux) and asked to use it, with the agent doing
the modelling. MagicaVoxel has no command line, so the agent does not drive its window: it writes
`.vox` files from code (`tools/vox_models.py`), checks them with turntable previews
(`tools/preview_stack.py`), and the owner opens the same files in MagicaVoxel to review and touch
them up. Once a `.vox` exists in `art/vox/`, it is the source of truth: the script never overwrites
it without `--force`.

`tools/build_stacks.py` now takes the first source that exists for each stack:
`art/vox/<name>.vox` (sliced as is by `tools/vox.py`, no export step), then
`art/views/<name>_views.png`, then the placeholder. A `.vox` must match the `STACKS` size exactly.
Axes: Z up, the object's front toward +Y. This is the route for anything with holes or overhangs;
the locomotive is the first model (open cab with window holes, spoked wheels, side rods).

## Consequences

- Source art lives in `art/`; only final slice sheets live in `game/assets/stacks/<name>/`.
- The slicer and the `.vox` reader/writer are tested with `pytest`.
