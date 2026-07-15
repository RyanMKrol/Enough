# custom/docs/LIMITATIONS.md — this project's trade-offs & limitations log

Customization overlay for `.harness/docs/LIMITATIONS.md`. **This is where your project's own
limitation/trade-off rows go** (golden rule 5): when a change introduces a trade-off, bottleneck, or known
limitation, add a row **here** — not in the pristine `docs/LIMITATIONS.md`, which is plugin-owned and
refreshed on upgrade. Harness upgrades never touch this file. (See `.harness/custom/CLAUDE.md`.)

Each row: what it is, *why* it was chosen, its **impact**, and *when to revisit*.

### 2026-07-15 — Sample content fixture stands in for real scenario packs
**What:** `Content/` is generated from the anki-builder project's "Japanese for Busy People"
output: 114 textbook cards sliced by category into 4 travel-themed decks (Greetings & basics /
Ordering food / At the bar / Getting around), so deck THEMES only loosely match their cards.
France & Germany reference the same Japanese card/audio files as pure placeholders.
**Why:** exercises the full catalog→deck→card→audio pipeline with real data shapes (the schema
in design-spec §8.1 is the contract the external pipeline will target) without blocking the app
build on content authoring.
**Impact:** the app is fully buildable/testable but not shippable content-wise; tests pin
fixture-specific numbers (30 greetings cards, £0.51 weekend savings) that will change with real
content.
**Revisit:** when anki-builder produces real scenario packs — regenerate `Content/`, update the
pinned fixture numbers in tests, give France/Germany real decks.

### 2026-07-15 — Purchases are stubbed (no StoreKit) until T061/T062
**What:** `PurchaseService` is a protocol with a stub that grants instantly and persists
locally; "Restore purchases" is a no-op.
**Why:** real IAP needs App Store Connect products + signing (human-gated T061); the stub keeps
every purchase-dependent screen buildable by the loop now, behind the same protocol StoreKit 2
will implement (T062).
**Impact:** no real money path; restore does nothing until T062.
**Revisit:** at T062.

### 2026-07-15 — Single app target; directories as namespaces
**What:** all code lives in one `Enough` target (`Sources/<Area>/`), not SPM packages.
**Why:** keeps XcodeGen config trivial and lets Haiku-tier builder agents add files without
manifest surgery; the architecture contract (`.harness/docs/designs/architecture.md`) enforces
boundaries by convention instead.
**Impact:** no compiler-enforced module boundaries (e.g. SRSKit could import SwiftUI unnoticed —
specs forbid it, review enforces it).
**Revisit:** if the app grows past ~20k LOC or boundary violations recur.
