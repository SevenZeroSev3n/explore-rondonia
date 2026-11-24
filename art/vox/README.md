# MagicaVoxel models (`art/vox/`)

Source models for objects that need holes or overhangs (ADR 0004). The game never loads these
files; `tools/build_stacks.py` slices them into `game/assets/stacks/<name>/<name>_slices.png`.

## Rules

- **One file per stack:** `art/vox/<name>.vox`, where `<name>` is a key of `build_stacks.STACKS`.
- **Exact size:** the model must be exactly the `STACKS` size (W × L × H). In MagicaVoxel that is
  the model's size box. The build stops if it differs.
- **Axes:** Z is up; the object's **front points to +Y**. If a model comes out back to front in
  the game, it was built facing −Y.
- **One model per file:** merge any extra models before saving.
- **Flat colours from the palette.** Every palette colour is used as is (no blending).

## Workflow

1. The agent writes a first version from code: `python3 tools/vox_models.py --only <name>`.
2. Open `art/vox/<name>.vox` in MagicaVoxel, touch it up and save over the same file. From then
   on that file is the source of truth: `vox_models.py` keeps it unless run with `--force`.
3. Rebuild the sheet: `python3 tools/build_stacks.py --only <name>`.
4. Check it: `python3 tools/preview_stack.py game/assets/stacks/<name>/<name>_slices.png --count H preview.png`
   (a turntable at 8 angles plus the raw slices), or run the game.

On Linux, MagicaVoxel runs through Wine:
`wine ~/Applications/MagicaVoxel/MagicaVoxel.exe`.

## Models

| Name | Size (W × L × H) | Notes |
|---|---|---|
| `locomotive` | 24 × 53 × 23 | Early-1900s narrow-gauge steam locomotive: spoked wheels with side rods, slatted cowcatcher, open cab with window holes. Original design, not a copy of a specific engine (`art/views/02-madeira-mamore.md`). |
