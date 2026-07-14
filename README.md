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

- Users browse and purchase language decks, roughly £3 each.
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
| T001 | Project scaffold + CI green on an empty build | ⬜ needs-human |

## Status

Early brainstorming / naming stage. No code yet.
