# Explore Rondônia

*Viaje por Rondônia · Travel across Rondônia*

A small cozy, bilingual (pt-BR / English) game set in the Brazilian state of Rondônia, in
**sprite-stacking** pixel art. Drive the real highways, stamp your tourist passport, and
photograph landmarks from the right angle to unlock what those places really look like.

> Status: pre-MVP. Drive a placeholder pickup along the real BR-364, Vilhena → Porto Velho.
> Dev build: https://sevenzerosev3n.github.io/explore-rondonia/
> Read [`CONTEXT.md`](CONTEXT.md) and the ADRs in [`docs/adr/`](docs/adr/).

## MVP

Start in Vilhena with an empty passport and drive a pickup truck up BR-364 on a stylized state
map (Vilhena → Ji-Paraná → Ariquemes → Porto Velho), plus one explorable diorama: the Madeira-Mamoré Railway
complex in Porto Velho, explored on foot. Collect 4 city stamps, 4 landmark photos and 3 real
roadside secrets to complete the passport (30–45 min). Desktop browser (keyboard / gamepad),
released on itch.io.

## Layout

```
art/       source art (AI 4-view sheets, .vox, raw exports) — never loaded by the game
tools/     Python pipeline: geodata → game JSON, 4-view → slice sheet (downloads in tools/cache/)
game/      the Godot 4 project; game/data/ holds geo/ (generated map), places/, i18n/
docs/      adr/ (decisions), reference/ (guides and local-only reference maps)
```

## License

Code: MIT. Original art: CC BY 4.0. Third-party data keeps its own license and is credited
in-game: OpenStreetMap (ODbL), IBGE (public), Wikimedia Commons photos (per-photo CC).
