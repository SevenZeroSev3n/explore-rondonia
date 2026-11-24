# ADR 0006 — Content as bilingual data

- Status: accepted
- Date: 2026-11-23
- Amended: 2026-11-23 (photo sources — Commons has almost nothing on the MVP secrets)

## Context

A large foreign audience is expected. Text in code makes translation and review hard.

## Decision

- pt-BR and English ship together from the MVP. Initial language follows the browser locale
  (English unless the browser prefers Portuguese); a PT/EN toggle is always visible.
- Player-facing strings live in `game/data/i18n/`; each place lives in `game/data/places/` with text in both
  languages, photos and credits. The agent drafts both languages; the owner reviews both.
- Local proper names stay in Portuguese with a short English gloss.
- Photos come from **Wikimedia Commons** when a free photo exists; otherwise from the **owner's own
  photos** or **third parties with written permission** (e.g. a park, a city hall). Every photo is
  credited with author and license (or permission) on its sheet and in the credits screen.

## Implementation (2026-11-24)

Each place lists its photos in `photos` (file, author, licence, licence URL, source URL, year,
bilingual caption). The sheet shows the first one with its caption and credit, and the credits
screen lists every photo. First photo: Cachoeira do Teotônio, Wilson Dias/Agência Brasil, 2007,
CC BY 3.0 BR (Wikimedia Commons, 960 px version).

## Consequences

- Adding a language is adding data, not code.
- Setur-RO material stays out until authorized.
