# Four-view sheets (ADR 0004)

Generate each image with any image generator, save it here as `<name>_views.png`, then run:

```bash
python3 tools/build_stacks.py
```

Stacks without a views file keep their code-drawn placeholder. Check the result in the game; if
a view comes out wrong, regenerate just that image and rerun with `--only <name>`.

## Layout every image must follow

A 2×2 grid on a **flat, plain, light background** (pure white is best):

| | left | right |
|---|---|---|
| **top row** | TOP: seen from directly above, **front pointing up** | SIDE: the right side, **front pointing left** |
| **bottom row** | FRONT: seen from the front | BACK: seen from behind |

No shadows, no text, no ground, no perspective. Same scale in all four views.

## Prompt template

> Pixel art orthographic reference sheet of **{subject}**, arranged in a 2x2 grid on a flat
> pure white background. Top-left: top view seen directly from above with the front pointing
> up. Top-right: side view of the right side with the front pointing left. Bottom-left: front
> view. Bottom-right: back view. All four views at the same scale, centred in their cell, no
> perspective, no shadows, no ground, no text, no labels, flat colours, limited palette.

## Subjects

| File | Target (W×L×H voxels) | {subject} |
|---|---|---|
| `truck_views.png` | 20×36×9 | a generic white compact pickup truck with no brand and no logos, an open cargo bed at the back and red-dirt-dusty tyres |
| `traveler_views.png` | 8×8×14 | a small traveler wearing a straw hat, an orange shirt and blue trousers, with a small backpack |
| `locomotive_views.png` | 18×40×17 | an early-1900s black steam locomotive with red trim, a tall smokestack at the front and the driver's cab at the back |
| `shed_views.png` | 64×36×20 | a long early-1900s brick railway workshop with a grey corrugated metal gable roof running along its length and a large wooden door on the long front side |
| `water_tower_views.png` | 16×16×36 | an early-1900s riveted steel cylindrical water tank with a conical roof on four tall steel legs with cross bracing, silver grey |
| `tree_views.png` | 24×24×26 | a tall Amazon Brazil-nut tree (castanheira) with a long straight grey trunk and a wide, flat, dense green crown |

The front of the shed is its long side with the door: in the TOP view that side points up.

Four views cannot carve holes or overhangs (the locomotive's open cab, the shed's door): those
stay solid. A MagicaVoxel model can replace any of them later with the same sheet format.
