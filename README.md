# Explore Rondônia

*Viaje por Rondônia · Travel across Rondônia*

An interactive, bilingual (pt-BR / English) map of the Brazilian state of Rondônia in
**sprite-stacking** pixel art. Drive the real highways, reach tourist spots, and see what
those places look like — first as a voxel-style diorama, then in real photos.

> Status: pre-MVP. Only the project skeleton and the architecture decisions exist.
> Read [`CONTEXT.md`](CONTEXT.md) and the ADRs in [`docs/adr/`](docs/adr/).

## MVP

The BR-364 end to end (Vilhena → Ji-Paraná → Ariquemes → Porto Velho), driven in a pickup
truck on a stylized state map, plus one explorable diorama: the Madeira-Mamoré Railway
complex in Porto Velho. Runs in the desktop browser (keyboard / gamepad).

## Layout

```
art/       source art (AI 4-view sheets, .vox, raw exports) — never loaded by the game
tools/     Python pipeline: geodata → game JSON, 4-view → slice sheet
data/      game data: geo/ (generated map), places/ (tourist sheets), i18n/ (strings)
game/      the Godot 4 project
docs/      adr/ (decisions), reference/ (guides and local-only reference maps)
```

## License

Code: MIT. Original art: CC BY 4.0. Third-party data keeps its own license and is credited
in-game: OpenStreetMap (ODbL), IBGE (public), Wikimedia Commons photos (per-photo CC).
