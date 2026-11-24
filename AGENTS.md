# Explore Rondônia — rules for agents

Read `CONTEXT.md` first; decisions live in `docs/adr/`. This file is an index: rules here,
detail in the linked documents.

## Current state

Layer 1 drives on the real map: BR-364 from Vilhena to Porto Velho, rivers, the state border and
town markers come from `game/data/geo/state_map.json` (built by `tools/geo/`); a dense forest of
six real tree species (plus shrubs) streams in chunks around the truck, chosen by habitat in
`scripts/world/forest.gd` and planted a bounded amount per frame (`game/scenes/main.tscn`, `scripts/world/state_map.gd`). The passport
works for city stamps: arriving stamps a city, the panel (P) teleports to visited ones, progress
and language are saved locally (`scripts/game/passport.gd`, autoloads `I18n` and `SaveStore`).
UI text is PT/EN from `game/data/i18n/strings.json`. Photo mode works on layer 1 (F, then Space):
`scripts/game/photo_rules.gd` judges frame, distance and angle window; the three secrets live in
`game/data/places/*.json` (bilingual text, sources, photo rules) and are projected onto the map by
`tools/geo/build_map.py` (rerun it after adding or moving a place). A valid photo opens the place
sheet. Real photos live in `game/assets/photos/` and in each place's `photos` list (author,
licence, source, bilingual caption; a test enforces it); on the web they are an HTML `<img>` over
the frame (`scripts/ui/web_photo.gd`). QA: a **debug** web build accepts `?open_sheet=<place id>`.

Layer 2: at Porto Velho, Enter opens the Madeira-Mamoré diorama (`scenes/diorama_efmm.tscn`,
`scripts/diorama/`): walk on foot, Q/E turn the camera, four landmark photos with a ±30° window
measured from the camera. Landmarks are place files with `diorama_layout`. With a turning camera,
`SpriteStack.view_rotation` keeps slices lifting up on screen and the diorama sorts entities by
screen y (ground stays at the minimum z).

The MVP loop is complete: a one-screen tutorial on a fresh save, "passport complete" once the
4 stamps, 4 Madeira-Mamoré photos and 3 secrets are in (after the last photo's sheet), and a
credits screen (`scripts/game/credits.gd`). One-off flags live in `SaveStore.flags`.
Integration tests must set `SaveStore.persist = false` and `SaveStore.flags = {"tutorial_seen": true}`
(and restore them) besides swapping the passport.

Integration tests that load `main.tscn` must swap `SaveStore.passport` for a fresh `Passport`
first, so they never write over the player's save. Art is built by `tools/build_stacks.py`: MagicaVoxel models in `art/vox/` first, then AI four-view sheets, then code-drawn placeholders. Slice sizes and counts in `build_stacks.STACKS` are a contract with the scenes. Before assuming a file
exists, check with `git ls-files`.

## Commands

Godot 4.7.2 on PATH as `godot`; web export templates (no-threads) installed for 4.7.2.

| Command | What it does |
|---|---|
| `godot --headless --path game --import` | Import assets; run before tests or export on a fresh clone |
| `godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://test/unit,res://test/integration -ginclude_subdirs -gexit` | GUT unit tests |
| `python -m pytest tools/tests -q` | Python pipeline tests (needs `pip install -r tools/requirements.txt`) |
| `python3 tools/build_stacks.py [--only NAME]` | Build every slice sheet: slices `art/vox/<name>.vox`, else carves `art/views/<name>_views.png` (AI 4-view sheets, see `art/views/00-workflow.md`), else the code-drawn placeholder |
| `python3 tools/vox_models.py [--only NAME] [--force]` | Write the code-built voxel models into `art/vox/` (never overwrites without `--force`; see `art/vox/README.md`) |
| `python3 tools/preview_stack.py SHEET --count N OUT.png` | Turntable preview of a slice sheet, drawn like `SpriteStack` |
| `python3 tools/geo/fetch.py [--force]` | Download OSM/IBGE geodata into `tools/cache/` (git-ignored) |
| `python3 tools/geo/build_map.py` | Rebuild `game/data/geo/state_map.json` from the cache |
| `godot --headless --path game --export-release "Web" ../build/web/index.html` | Web build into `build/` |

CI (`.github/workflows/web.yml`) runs both test suites on every push/PR and publishes the web
build to GitHub Pages from `main`.

## Before touching X, read Y

| X | Y |
|---|---|
| Sprite stacking, slice sheets, Godot settings | `docs/reference/sprite-stacking-guide.md` |
| Engine, export, renderer | `docs/adr/0001-godot-4-web-first.md` |
| Map, camera, layers, scale | `docs/adr/0002-two-map-layers.md`, `docs/adr/0003-geodata-pipeline.md` |
| Art assets | `docs/adr/0004-art-pipeline-ai-plus-procedural.md`, `docs/adr/0005-visual-style.md` |
| Place sheets, text, photos, i18n | `docs/adr/0006-content-as-bilingual-data.md` |
| Game loop, passport, photo mode, secrets | `docs/adr/0008-cozy-passport-game-loop.md`, `docs/research/roadside-secrets.md` |
| CI, hosting, tests | `docs/adr/0007-repo-ci-hosting-tests.md` |

## Rules

- Never commit, push or open a PR without an explicit request from the owner in the conversation.
- The game loads only files inside `game/` (generated map in `game/data/geo/`). Never load files from `art/`.
- Slice sheets: one row, ground on the left, art facing up (−Y), width divisible by slice count.
- Player-facing strings never go in code: they go in `game/data/i18n/` or `game/data/places/`, in both
  pt-BR and English.
- Third-party data and photos must carry their license and credit into the credits data.
- Reference maps in `docs/reference/*.jpg|gif` are local-only (unclear license); never commit them.
- Out-of-MVP features (see `CONTEXT.md`) → stop and ask.
- Don't weaken a test to make it pass.
