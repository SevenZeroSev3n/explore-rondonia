# ADR 0001 — Godot 4, web first, single-thread export

- Status: accepted
- Date: 2026-11-23

## Context

The map must be reachable from a shareable link (portfolio, educational use, foreign audience),
with desktop as a bonus. The reference sprite-stacking guide and its `SpriteStack` node target
Godot 4. Alternative considered: a native web stack (PixiJS/Phaser + TypeScript) — lighter in the
browser, but no visual editor, no ready stacking node and no free desktop export.

## Decision

Godot 4 (latest stable at setup), **Compatibility renderer** (WebGL2), web export **without
threads**, so no cross-origin-isolation headers are needed and any static host works. Desktop
exports come from the same project later. Input goes through Godot input actions (keyboard and
gamepad in the MVP).

## Consequences

- Performance budget is set by WebGL2 in the browser: many static stacks must be pre-rendered to
  single sprites (guide §9).
- Touch/mobile is out of the MVP; the input-action layer keeps it addable.
