# ADR 0008 — It's a game: cozy passport-and-photo loop

- Status: accepted
- Date: 2026-11-23
- Amends: ADR 0002 (scope), ADR 0007 (publishing)

## Context

The foundation grill framed the project as an exploration experience with no game goals, and
left missions and collecting out of the MVP. The owner clarified it is meant to be a small game.
It needs a loop: what the player wants, what they earn, when it ends. Genres considered: cozy
exploration and collection, freight/delivery trucking, arcade driving, story adventure.

## Decision

**Cozy exploration and collection around a tourist passport.**

- **Goal:** complete the passport. Reaching a city stamps it (no photo needed).
- **Photo mode:** the camera works anywhere, on both layers. A photo counts only for registered
  photo spots, when the landmark is **fully in frame**, within a sensible distance, and the camera
  is **inside that landmark's angle window** (about ±30° around a per-landmark heading). Pass/fail
  only in the MVP, with a subtle hint ("try another angle"). On layer 1 the view is top-down, so
  the window is wider (±50°, from the side facing the road); ±30° is for the rotating dioramas. A valid photo unlocks that place's
  sheet (ficha) with the real photo — the real place is the reward.
- **On foot in dioramas:** on layer 2 the player leaves the vehicle and walks a small
  sprite-stacked traveler, to circle landmarks for the right angle. Layer 1 is always the vehicle.
- **Light friction, no game over:** BR-364 potholes and dirt stretches slow the vehicle; secrets
  off the road reward leaving the asphalt.
- **Secrets are real places** near BR-364 (viewpoints, waterfalls, bridges, river beaches),
  researched with sources, approved by the owner, each with a real-photo sheet. MVP secrets
  (`docs/research/roadside-secrets.md`): Cachoeira do Rio Mandi (Nova União), the Rondon telegraph
  station on the Machado river (Ji-Paraná) and Cachoeira do Teotônio (Porto Velho).
- **Start:** Vilhena, empty passport, a one-screen embedded tutorial (drive, open passport, take a
  photo); the Vilhena stamp is the first reward. Free order afterwards.
- **MVP ending:** 4 city stamps (Vilhena, Ji-Paraná, Ariquemes, Porto Velho) + the 4 Madeira-Mamoré
  photos (locomotive, railway sheds, Três Caixas d'Água, Madeira river bank) + the 3 roadside secrets
  → "passport complete" screen, then credits. Target session: 30–45 minutes.
- **Publishing:** itch.io is the main showcase (page with GIF and screenshots, PT/EN); GitHub Pages
  stays as the continuously updated development build.

## Consequences

- Photo validation (in-frame, distance, angle window) and passport progress are pure logic and get
  GUT tests.
- One extra asset: the traveler on foot.
- Still out of the MVP: score/stars on photos, economy, freight, traffic/NPCs, story, fail states.
