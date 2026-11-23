# ADR 0006 — Content as bilingual data

- Status: accepted
- Date: 2026-11-23
- Amended: 2026-11-23 (photo sources — Commons has almost nothing on the MVP secrets)

## Context

A large foreign audience is expected. Text in code makes translation and review hard.

## Decision

- pt-BR and English ship together from the MVP. Initial language follows the browser locale
  (English unless the browser prefers Portuguese); a PT/EN toggle is always visible.
- Player-facing strings live in `data/i18n/`; each place lives in `data/places/` with text in both
  languages, photos and credits. The agent drafts both languages; the owner reviews both.
- Local proper names stay in Portuguese with a short English gloss.
- Photos come from **Wikimedia Commons** when a free photo exists; otherwise from the **owner's own
  photos** or **third parties with written permission** (e.g. a park, a city hall). Every photo is
  credited with author and license (or permission) on its sheet and in the credits screen.

## Consequences

- Adding a language is adding data, not code.
- Setur-RO material stays out until authorized.
