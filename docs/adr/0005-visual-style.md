# ADR 0005 — Visual style: 480×270, fixed palette

- Status: accepted
- Date: 2026-11-23

## Context

The guide suggests 320×180, which is too tight to read a map with cities and labels.

## Decision

- Internal resolution **480×270**, viewport stretch, integer scale (×4 = 1080p exact; ×2 with
  letterbox at 720p). Nearest filter, no mipmaps, 2D transforms snapped to pixel.
- A fixed palette of ~32 colours: Amazonian greens, red dirt roads, river blues.
- Outline drawn once on the finished stack, never per slice.
- UI font (2026-11-24): **Pixelify Sans** (OFL) at **13 px**, the size where its pixel grid lands
  on whole screen pixels and every Portuguese accent stays distinct (at 11 px "á" reads as "à"
  and "ã" loses its tilde); antialiasing and hinting off; set once in `game/assets/ui_theme.tres`.
- Place sheets (fichas) are pixel-framed with a bitmap font, but **real photos are shown at full
  resolution, not pixelated**, to mark the contrast between the game and the real place.
