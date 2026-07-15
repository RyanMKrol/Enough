# Enough

An iOS app for learning "enough" of a language — just enough to get by on a
short trip, like a weekend away or a week's holiday.

## The idea

Most language apps optimize for long-term fluency. Enough optimizes for the
opposite: a focused, short burst of learning aimed at a specific upcoming
trip. The goal isn't mastery, it's competence for a handful of real
situations (ordering food, asking directions, basic pleasantries, etc.).

Under the hood, the app uses spaced-repetition flashcard mechanics (in the
spirit of Anki) to drive learning efficiently in a short window of time.

## How it works (rough shape)

- Users browse and purchase scenario-sized language packs (£1 each) or discounted trip
  bundles (Weekend / The whole week) — one-time purchases, no subscription.
- Each deck is scoped to "enough for a trip" rather than a whole language —
  curated, practical vocabulary and phrases rather than exhaustive courses.
- Spaced repetition drives review scheduling so a small deck can be learned
  solidly in a few days.
- Initial focus: enough of a language for a week or weekend away.

## Building this

This repo uses an autonomous build harness (`.harness/`) to work through an implementation
backlog one task at a time — see [`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) for
how it works, and [`CLAUDE.md`](./CLAUDE.md) for project conventions.

### Implementation status

| Task | Description | Status |
|------|-------------|--------|
| T001 | Project scaffold + CI green on an empty build | ✅ done |
| T002–T064 | Full v1 backlog (design system → content/persistence/SRS → screens → polish), authored 2026-07-15 | 📋 pending |
| T065–T088 | Axiom-derived wave: accessibility, privacy manifest/policy, schema guardrails, price localization, and 14 audit-and-fix sweeps | 📋 pending |

The live backlog + statuses are in `.harness/tracking/TASKS.json`; each task's spec is in
`.harness/tasks/`. The design source of truth is
[`.harness/docs/designs/design-spec.md`](./.harness/docs/designs/design-spec.md) and the shared
type/name contract is
[`.harness/docs/designs/architecture.md`](./.harness/docs/designs/architecture.md).

## Status

Bare app skeleton plus planning collateral: an XcodeGen-generated iOS app (`Enough`) with a
placeholder screen, a unit test target, SwiftLint + swift-format wired into CI, `build_run.sh`
for local build/install/launch/screenshot on the simulator, and a bundled sample content fixture
(`Content/` — 4 Japanese decks, 114 cards + audio, generated from the anki-builder project; see
design-spec §8.1 for the schema). No product features yet — the backlog builds them.

## Development

- Generate the Xcode project: `xcodegen generate` (regenerates `Enough.xcodeproj` from
  `project.yml` — the `.xcodeproj` itself is git-ignored).
- Build + launch on a simulator with a screenshot: `./build_run.sh`.
- Run the full local Definition of Done: see `.harness/config/harness.env`'s `LOCAL_DOD`.
