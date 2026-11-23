# ADR 0007 — Public repo, GitHub Pages, tests on pure logic

- Status: accepted
- Date: 2026-11-23

## Decision

- Public GitHub repository **`explore-rondonia`** (the local folder may stay `rondonexplorer`).
- GitHub Actions exports the Godot web build headless on every merge to `main` and publishes it
  to **GitHub Pages**. itch.io may mirror it later.
- Tests on pure logic: `pytest` for the geodata pipeline and the slicer; **GUT** in Godot for the
  road graph, autopilot and progress save. Look and driving feel are checked by hand on the web
  build.
- Licenses: code MIT, original art CC BY 4.0, third-party data under its own license, credited.
