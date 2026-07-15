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

### 2026-07-15 — Stub-era prices are catalog-GBP, formatted en_GB
**What:** until real StoreKit lands, all displayed prices come from `Content/catalog.json`'s
`priceGBP` formatted for `en_GB` (via `PricingCalculator`, surfaced through the stub's
`displayPrice`).
**Why:** there is no StoreKit product to ask yet; the catalog is the only price source, and a
single fixed locale keeps the pinned test strings ("£2.49") deterministic.
**Impact:** every non-UK storefront would see the wrong currency/amount if this shipped —
Apple localizes real prices across ~175 storefronts and Guideline 3.1.x flags hardcoded ones.
**Revisit:** T062 swaps unit prices to `product.displayPrice`; T073 localizes computed
savings/summary lines off `Product.price` decimals.

### 2026-07-15 — Tertiary/faint text tokens fail WCAG AA at small sizes
**What:** `tertiaryText #8e8e93` (≈3:1), `faintText #a0a0a6` and inactive-tab `#b0b0b6`
(≈2.5:1) sit below the 4.5:1 AA contrast floor for sub-18pt text on white.
**Why:** they are the design handoff's exact values, used for decorative/duplicated
information only (e.g. inactive tab labels whose selection state is also conveyed by the
accent icon), matching iOS system-grey conventions.
**Impact:** any use of these tokens as the SOLE carrier of information is an accessibility
defect.
**Revisit:** at the accessibility conformance task / accessibility audit — flag and fix any
non-decorative usage found; consider darkening tertiaryText toward `#767676` if audits keep
flagging it.

### 2026-07-15 — SwiftData schema is not CloudKit-sync-compatible
**What:** the current schema uses non-optional fields without defaults and code-level
uniqueness (fetch-before-insert upserts) — all fine locally, but CloudKit-backed SwiftData
requires optionals/defaults on every property and bans unique constraints.
**Why:** v1 is deliberately on-device only (no accounts, StoreKit restore covers purchases);
designing for CloudKit now would complicate every model and test for a feature that may never
ship.
**Impact:** adopting cross-device sync later requires a schema migration (add defaults/
optionals) — a `SchemaV2` + migration stage, not a rewrite.
**Revisit:** if/when cross-device sync of SRS state becomes a goal.
