# ADR 0007 — Public repo, GitHub Pages, tests on pure logic

- Status: accepted
- Date: 2026-11-23
- Amended by: ADR 0008 (itch.io becomes the main showcase)

## Decision

- Public GitHub repository **`explore-rondonia`** (the local folder may stay `rondonexplorer`).
- GitHub Actions exports the Godot web build headless on every merge to `main` and publishes it
  to **GitHub Pages**, the development build. Releases go to **itch.io**, the main showcase
  (ADR 0008).
- Tests on pure logic: `pytest` for the geodata pipeline and the slicer; **GUT** in Godot for the
  road graph, autopilot, progress save, passport and photo validation. Look and driving feel are
  checked by hand on the web build.
- Licenses: code MIT, original art CC BY 4.0, third-party data under its own license, credited.
