# Explore Rondônia — rules for agents

Read `CONTEXT.md` first; decisions live in `docs/adr/`. This file is an index: rules here,
detail in the linked documents.

## Current state

Skeleton only: folders, docs and ADRs. No Godot project, no pipeline code yet. Before assuming a
file exists, check with `git ls-files`.

## Before touching X, read Y

| X | Y |
|---|---|
| Sprite stacking, slice sheets, Godot settings | `docs/reference/sprite-stacking-guide.md` |
| Engine, export, renderer | `docs/adr/0001-godot-4-web-first.md` |
| Map, camera, layers, scale | `docs/adr/0002-two-map-layers.md`, `docs/adr/0003-geodata-pipeline.md` |
| Art assets | `docs/adr/0004-art-pipeline-ai-plus-procedural.md`, `docs/adr/0005-visual-style.md` |
| Place sheets, text, photos, i18n | `docs/adr/0006-content-as-bilingual-data.md` |
| CI, hosting, tests | `docs/adr/0007-repo-ci-hosting-tests.md` |

## Rules

- Never commit, push or open a PR without an explicit request from the owner in the conversation.
- The game loads only `game/` and generated `data/`. Never load files from `art/`.
- Slice sheets: one row, ground on the left, art facing up (−Y), width divisible by slice count.
- Player-facing strings never go in code: they go in `data/i18n/` or `data/places/`, in both
  pt-BR and English.
- Third-party data and photos must carry their license and credit into the credits data.
- Reference maps in `docs/reference/*.jpg|gif` are local-only (unclear license); never commit them.
- Out-of-MVP features (see `CONTEXT.md`) → stop and ask.
- Don't weaken a test to make it pass.
