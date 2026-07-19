# Enough

Enough is a native SwiftUI iOS app that teaches just enough of a language for a short trip —
scenario-sized packs (£1 each, or discounted trip bundles for a weekend or a week away;
one-time purchases, no subscription, StoreKit stubbed for now) learned through an Anki-style
SM-2 spaced-repetition engine.

## Requirements

Enough targets **iOS 26 and above** (excluding iOS 18-25 devices). This is a deliberate
choice — Enough is a never-shipped app for current-generation iPhones, so it ships iOS
26-only, which unblocks adopting iOS 26-only APIs (e.g. Liquid Glass `glassEffect()`)
unconditionally, with no `#available` guards or pre-26 fallbacks.

## Building this

This repo uses an autonomous build harness (`.harness/`) to work through an implementation
backlog one task at a time — see [`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) for
how it works, and [`CLAUDE.md`](./CLAUDE.md) for project conventions.

## What's implemented

- **Onboarding** — welcome screen, country picker, and a plan/purchase screen (bundle or
  à-la-carte pack selection with running totals) that hands off into the main shell.
- **Main shell** — a floating liquid-glass tab bar with four tabs: Learn (Home), Reviews,
  Progress, and Browse.
- **Learn & review sessions** — multiple-choice learn sessions and tap-to-reveal flashcard
  review sessions, both driving the SM-2 schedule via `SessionEngine`/`StudyService`, ending in
  a session-complete screen (ring race, stats, "learn 5 more").
- **Reviews tab** — due ring plus Due/Learning/Mastered tiles and per-deck strength bars.
- **Browse tab** — country-sectioned store listing packs/bundles with prices, buy, and restore.
- **Progress** — streak pill, streak card, and week-dot row components (the full stat-tile +
  readiness-ring tab assembly is in progress).
- **Streaks & readiness** — `StatsService` computes streaks, week dots, and lifetime totals.
- **Review-due local notifications** — `NotificationsService` schedules a local notification
  for the next due review, requesting permission after the first completed session.
- **Debug god-mode menu** — a hidden menu (shake gesture or the `-debug-menu` launch argument)
  with settings to unlock all packs, time-travel the app clock, reset all app data, fire a test
  notification, and inspect pending schedules. The `-demo-state` launch argument wipes and seeds
  a mid-trip demo fixture (used by `build_run.sh` for screenshots).

## Architecture

- `Sources/App` — `AppState`, `RootView`, `MainShellView`, and `AppServices` (DI root).
- `CoreKit` — `DateProvider` and shared utilities.
- `DesignSystem` — tokens (`EnoughFont`, colors, layout) and reusable visual components.
- `ContentKit` — content catalog models + `ContentStore` (read-only bundled data).
- `Persistence` — SwiftData `...Record` models and `...Store` types.
- `SRSKit` — pure SM-2 spaced-repetition logic and the session engine (no SwiftData/SwiftUI).
- `Services` — study, purchases, audio, stats, and notifications glue between the layers above
  and the UI.
- `Features/<Area>` — screens, one directory per area (Onboarding, Home, Session, Reviews,
  Progress, Browse, Debug, …).

See [`.harness/docs/designs/architecture.md`](./.harness/docs/designs/architecture.md) for exact
signatures and [`.harness/docs/designs/design-spec.md`](./.harness/docs/designs/design-spec.md)
for design truth.

## Content

Decks, cards, and audio are bundled data under `Content/` (`catalog.json`, `decks/*.json`,
`audio/*.mp3`) in the schema described in design-spec §8.1, produced by the external
anki-builder pipeline. The current content is a placeholder fixture — Japanese textbook slices;
the France and Germany country entries currently reuse the same Japanese files.

## Development

- Generate the Xcode project: `xcodegen generate` (regenerates `Enough.xcodeproj` from
  `project.yml` — the `.xcodeproj` itself is git-ignored).
- Build + launch on a simulator with a screenshot: `./build_run.sh`.
- Run the full local Definition of Done: see `.harness/config/harness.env`'s `LOCAL_DOD`.
