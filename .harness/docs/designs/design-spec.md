# Enough — canonical design & product spec

This is the single source of truth for what the app looks like and how it behaves. It was
distilled from the Claude Design handoff bundle (`design_handoff_enough`, July 2026) plus the
product decisions recorded in §0. Backlog tasks point here via their `design` field — read the
sections relevant to your task before building. Where a task's own spec (`.harness/tasks/TNNN.md`)
and this doc disagree, the task spec wins.

---

## 0. Product decisions (settled — do not reopen)

- **Platform:** native **SwiftUI, iOS 18+**, iPhone only. Recreate the design with real system
  components (navigation stacks, grouped lists, material/blur tab bar, SF Pro system font, system
  haptics) — explicitly NOT a bespoke cross-platform look.
- **Voice & tone: Confident & minimal.** Reference line: "Enough to get by. Order a coffee, ask
  for the bill, say thanks like a local." Short sentences, no exclamation-mark cheerleading. All
  mock copy in this doc is already in this voice — reuse it verbatim wherever given.
- **No user accounts.** Everything is on-device (SwiftData). The welcome screen's designed
  "I already have an account" link is REPLACED by a "Restore purchases" text link (same style,
  same position) — purchase redeemability comes from StoreKit restore, not accounts.
- **Purchases:** one-time IAP — £1 per pack, discounted bundles, no subscription. v1 ships a
  **stubbed `PurchaseService`** (protocol shaped like StoreKit 2: `products`, `purchase`,
  `restorePurchases`, owned-set stream; stub grants instantly and persists locally). Real
  StoreKit 2 arrives in a later task behind the same protocol.
- **Session modes:** **multiple-choice to LEARN** a deck the first time (lower friction);
  **tap-to-reveal flashcard with Again/Hard/Good/Easy for REVIEWS** (drives the SRS schedule).
- **Spaced repetition:** SM-2-style. Card states New → Learning → Review (young → mature =
  "Mastered"). A deck is never "finished" — after first pass it shows "Learned" and stays in the
  review rotation.
- **Gamification is moderate:** streaks + per-trip "survival readiness" %. **No XP or points
  anywhere** (deliberately removed).
- **Content is data:** the app consumes the bundled `Content/` catalog (schema in §8) authored by
  an external pipeline (anki-builder). Never hardcode deck/card content in Swift.

## 1. Design tokens

### 1.1 Colors (OKLCH source → precomputed sRGB hex; use the hex in code)

Country accents (shared lightness/chroma, rotated hue — the active trip's accent tints the whole app):

| Token | OKLCH | Hex |
|---|---|---|
| japanAccent (default in mocks) | oklch(0.62 0.19 25) | `#e24947` |
| japanTint | oklch(0.96 0.035 25) | `#ffe9e6` |
| japanDeep (text on tint) | oklch(0.5 0.19 25) | `#b71824` |
| franceAccent | oklch(0.60 0.16 258) | `#3d7ede` |
| franceTint | oklch(0.96 0.03 258) | `#e6f3ff` |
| franceDeep | oklch(0.48 0.16 258) | `#1659b5` |
| germanyAccent | oklch(0.66 0.16 68) | `#d07b00` |
| germanyTint | oklch(0.96 0.035 68) | `#ffeed9` |
| germanyDeep | oklch(0.54 0.16 68) | `#a95600` |

Semantic (FIXED hues, never country-themed):

| Token | OKLCH | Hex | Use |
|---|---|---|---|
| linkBlue | oklch(0.6 0.16 258) | `#3d7ede` | text links, review/refresh iconography, Home "Review" pill |
| successGreen | oklch(0.55 0.14 150) | `#1c8742` | correct answers, "Learned" state, Good grade |
| successTint | oklch(0.95 0.05 150) | `#d8f9dd` | green fills/sheets |
| successDeep | oklch(0.48 0.14 150) | `#00722e` | text on green tint |
| easyBlue | oklch(0.5 0.13 250) | `#1666aa` | Easy grade |
| easyTint | oklch(0.95 0.05 220) | `#caf7ff` | Easy grade fill |
| streakAmber | oklch(0.65 0.17 50) | `#de6907` | flame, streak card |
| streakAmberTint | oklch(0.96 0.035 50) | `#ffecdd` | streak card gradient base |

Neutrals: canvas/grouped bg `#f2f2f7`; surface `#ffffff`; secondary surface/inset `#f7f7fa`;
label `#1c1c1e`; secondary text `#6b6b70`; tertiary `#8e8e93`; faint `#a0a0a6`/`#b0b0b6`;
hairline border `rgba(0,0,0,0.06–0.10)`. Grade "Hard" chip: `#f2f2f7` fill (pressed `#ececef`),
`#6b6b70` text.

Contrast caveat: tertiary `#8e8e93` (~3:1) and faint `#a0a0a6`/`#b0b0b6` (~2.5:1) fail WCAG AA
(4.5:1) for small text on white — use them only for decorative or REDUNDANT information (e.g.
inactive tab labels whose state is also conveyed by the accent icon), never as the sole carrier
of meaning. `secondaryText #6b6b70` passes and is the floor for information-bearing small text.

Welcome card-stack back tints: blue `#e8f5ff` (oklch 0.965 0.028 258), orange `#fff0df`
(oklch 0.965 0.03 68). Japan header band `#fff0ee`, band border `#fedbd7`, country label on band
`#a43b38`, pronunciation-pill text `#a45953`.

### 1.2 Typography — SF Pro (system font, never bundled)

Large Title 34 Bold (tracking −0.02em) · Wordmark 44 Bold (−0.03em) · Screen titles 30–32 Bold ·
Headline/card phrase 20–24 Semibold-Bold · MC question phrase 34 Bold · flashcard phrase 36 ·
Body 17 Regular · Subhead/pronunciation 15 Regular · Footnote/meta 12–13 Regular ·
Eyebrow 12–13 Semibold, ~0.06em tracking, uppercase, muted.

### 1.3 Radius / spacing / shadows

Radius: buttons 15–16; small tiles/chips 10–15; cards 18–20 (list/detail) and 24–28
(hero/flashcard); pills/circles fully rounded. Screen horizontal padding 18–28; card interior
16–22; list-row vertical 11–16; section gaps 14–24. Shadows — resting card
`0 1px 3px rgba(0,0,0,.05)`; raised card `0 10–20px 24–42px rgba(0,0,0,.08–.14)`; accent button
`0 6px 18px accent@35%` (keep subtle when another button sits directly beneath); tab bar
`0 6px 22px rgba(0,0,0,.1)` + inset 0.5px hairline.

### 1.4 Motion vocabulary (exact durations/easings)

- Card-stack bob: translateY ±6px, 4s ease-in-out, infinite (back cards ±4px, out of phase).
- Progress ring fill: from empty, ~1.1–1.3s ease-out on appear.
- Progress bar grow: scaleX 0→1, ~1s ease-out, anchored left.
- Check pop: scale 0 → 1.18 → 1, ~0.5s spring (cubic-bezier(.2,1.5,.4,1)).
- Wrong-answer shake: ~0.5s.
- Audio pulse ring: scale 0.85→1.7, opacity 0.6→0, 2–2.4s, infinite.
- Flame flicker: subtle scale+rotate, 2.2s ease-in-out, infinite.
- Card-to-card: finished card slides off LEFT as next rises FROM BELOW, shallow spring ~0.35s.
- Motion philosophy: "small, physical, purposeful — never confetti-for-its-own-sake."

### 1.5 Haptics (system, never custom)

Light tap on select · soft success on correct · gentle double-tick on wrong
(UIImpactFeedbackGenerator/.light, UINotificationFeedbackGenerator .success/.error).

## 2. Onboarding (native push/pop nav stack; back NEVER loses entered answers)

Flow: Welcome → Step 1 of 3 country → Step 2 of 3 trip shape → Your plan (untitled step). The
primary button is graphite `#1c1c1e` until a country is chosen, then **morphs to the country
accent** — "the moment the app becomes yours."

### 2.1 Welcome ("cold open")

Full-bleed white, vertically centered hero, CTAs pinned bottom (padding ~96/28/40).
- **Card stack** (in a ~255×292 stage): three identical 165×224 cards, radius 28. Back-left
  tinted `#e8f5ff` rotated −10°; back-right `#fff0df` rotated +10°; front upright, white, border
  `rgba(0,0,0,.07)`, shadow `0 20px 42px rgba(0,0,0,.14)`. All bob (4s, front ±6px, backs ±4px,
  phase-offset). Front card = **"premium panel"** composition: full-width tinted header band
  (`#fff0ee`, bottom border `#fedbd7`, padding 16×18) holding a 30×30 white rounded-square flag
  chip (13px red circle) + "Japan" 13px semibold `#a43b38`; below, a clean stage with ありがとう
  (24 Bold) centered and "arigatō" in a tinted pill (12.5 Medium `#a45953` on `#ffe9e6`,
  padding 6×12, fully rounded, 0.04em tracking).
- **Wordmark** "Enough." 44 Bold, −0.03em, with the period in japanAccent `#e24947`; positioned
  to graze/overlap only the blank bottom edge of the front card.
- **Tagline:** "Learn just enough of a language to get through the trip. A weekend. A week. No
  more than you need." — 18 Regular `#6b6b70`, max-width 280, centered.
- **Primary button** "Get started" — graphite `#1c1c1e`, white 17 Semibold, 54 tall, radius 16.
- **Text link** "Restore purchases" — linkBlue, 15. (Replaces the designed account link — §0.)

### 2.2 Choose a country (Step 1 of 3)

Back-chevron pill + eyebrow "STEP 1 OF 3"; large title "Where are you headed?"; subtitle "Pick a
country to unlock its decks."; 2-column grid of country cards; primary "Continue" pinned bottom.
- Country card: white, radius 20, 46px flag tile, name 18 Semibold, subtitle "日本語 · 4 decks"
  (native language name + deck count from the catalog). Unselected: 1px hairline
  `rgba(0,0,0,.08)`, no shadow. Selected: 2.5px accent ring + accent-tinted shadow + filled
  accent check badge (22px circle, top-right).
- Dashed "More soon" tile: "Italy · Spain · Thailand".
- Selecting a country flips the app accent immediately (button morphs graphite → accent).
- Countries at launch: Japan (日本語), France (Français), Germany (Deutsch) — from the catalog.

### 2.3 Shape your trip (Step 2 of 3)

Title "Shape your trip". Question "How long are you there?" → iOS segmented control
"A weekend / A week" (track `#f2f2f7`, selected segment white with subtle shadow). Question
"What will you be doing?" → multi-select scenario chips: Eating out, Getting around, Greetings,
Nightlife, Shopping, Emergencies. Selected chip = accent-tinted fill + 1.5px inset accent ring +
accent text; unselected = `#f2f2f7` fill, `#6b6b70` text; chips fill with a small spring on tap.
CTA "Build my plan" (accent).

### 2.4 Your plan (plan + purchase)

Title "Your plan", subtitle "Built from your answers — pick a bundle or add packs à la carte."
The interview SEEDS the plan; the user freely edits; no forced re-interview.
- **Bundle rows** (radio-style single choice): "Weekend" — subtitle "3 essential packs ·
  save £0.51" — £2.49 — "POPULAR" tag — selected by default (2px accent ring, tinted shadow,
  filled radio). "The whole week" — "Every Japan pack · save £<computed>" — £3.49 (price from
  catalog) — hairline border, empty radio. **Savings are computed**: sum of member pack prices −
  bundle price.
- Divider "or choose packs", then a grouped pack checklist (hairline dividers inset 49px): each
  row = 22px check/circle + pack name + card count + right status. Packs in the selected bundle:
  filled accent check + bundle name; packs outside it: empty ring + "+ £1". Tapping toggles
  à-la-carte additions.
- Link: magnifier icon + "Browse all Japan decks" (linkBlue).
- Sticky footer: summary "Weekend · 3 packs" + total "£2.49"; primary "Get the bundle" (accent);
  microcopy "One-time purchase · yours forever".
- Purchase goes through `PurchaseService`; on success the app enters the main shell with owned
  decks unlocked.

## 3. Main shell — floating liquid-glass tab bar

4 tabs: **Learn, Reviews, Progress, Browse**. Floating pill: `rgba(255,255,255,.82)` +
blur(20)/saturate(180%) material, radius 26, shadow `0 6px 22px rgba(0,0,0,.1)`, inset 0.5px
hairline. Active tab = accent icon + 10 Semibold label; inactive `#b0b0b6`. Tab bar shows on the
four top-level tabs; deck detail and sessions are full-screen (tab bar hidden). The whole app
surface is tinted by the active trip's accent.

## 4. Learn tab (Home) — "what should I do right now?"

Top→bottom:
- Large title "Learn"; subtitle "<Duration> in <City/Country> · Day N" (e.g. "Weekend in Tokyo ·
  Day 2" — day counter from trip start date). **Streak pill** top-right: white pill, flickering
  flame (streakAmber), bold count.
- **Continue hero card**: accent-tinted gradient, radius 24, eyebrow "Continue". Left = 64px
  progress ring (accent, % in center, animates on every visit); middle = deck name + "8 of 30
  cards · about 6 min left" (time estimate ~25s/card, rounded); right = 44px accent circular
  play button. Tapping resumes the deck's learn session.
- **Reviews banner** (only when reviews are due): white card, blue circular-arrow icon, "12 cards
  ready to review" + "Spaced repetition · keeps them stuck", right-hand "Review" pill
  (blue-tinted). Launches a review session.
- **"Your decks"** grouped list — each row: 34px deck icon (SF Symbol on tint) + name + thin
  progress bar; right status: "Learned" (green check — never "Done"), "8/30", or "New".
  Tapping opens deck detail.

## 5. Deck detail

Full-screen, accent-tinted hero header: frosted circular back + ellipsis buttons; deck icon;
title; subtitle "Japanese · <deck subtitle>"; translucent white meta chips "30 cards / ~12 min /
Audio". Below: progress row "8 of 30 learned" + "27%" with animated bar. "In this deck" sample
list: rows of target phrase (17 Semibold) + "pronunciation · english" subline (15) + 34px
circular accent-tinted audio button (tap ripples the speaker once — same control as sessions).
Sticky bottom action bar over a white gradient fade: primary "Continue learning" (accent, SUBTLE
shadow so the secondary stays crisp) + secondary "Practice all N" (accent-tinted) — practice mode
runs the whole deck as multiple-choice WITHOUT writing SRS state. Open transition: detail rises
from the tapped card (matchedGeometry flag/icon tile settles into the hero) — nice-to-have, not
load-bearing.

## 6. Sessions

Session round length: 12 cards (or all remaining if fewer). Progress bar + "n/12" counter
increment on GRADE, not on card show. Between cards: off-left / in-from-below spring ~0.35s.
Close (X) abandons the session (state for graded cards is kept). Every card auto-plays its audio
ONCE on appearance; the speaker button replays it (pulsing-ring affordance while idle).

### 6a. Multiple choice (LEARN mode)

- Question: top bar = X + thin progress bar + "3/12". Center: 60px accent-tinted audio button
  with pulsing ring; target phrase 34 Bold; pronunciation 15; prompt "What does this mean?";
  4 answer rows (`#f7f7fa`, radius 15) — 1 correct English meaning + 3 distractors drawn from
  other cards in the same deck (fallback: same country's other decks).
- Correct: chosen row springs to successGreen fill + white check pop (scale 0→1.18→1); other
  rows fade to `#c0c0c6`; soft-success haptic; green result sheet slides up (radius 24 top):
  "Nice." + "You'll see this again in <computed interval>" + forward chevron. Swipe or tap → next.
- Incorrect: wrong row shakes ~0.5s, turns accent-red-tinted with X; the correct row outlines
  green with check; double-tick haptic; calm red-tinted correction sheet: "Not quite" + "<target>
  is the <bolded key word>. We'll bring this back soon." (explanation from the card's
  english/notes). The missed card is RE-QUEUED later in the same session. No punishment.
- MC results feed the SRS engine: correct-first-try ≈ Good; wrong ≈ Again.

### 6b. Tap-to-reveal flashcard (REVIEW mode)

Canvas `#f2f2f7` (vs white for MC). Front: white card radius 28, big shadow, 60px audio button +
target phrase (36) ONLY — pronunciation hidden until reveal; hint "Tap the card to reveal". Tap →
3D flip; revealed: front content compresses into a tinted header band (target + pronunciation)
over the English answer + audio button; prompt "How well did you know it?"; grade row
**Again / Hard / Good / Easy** — fills red-tinted / neutral `#f2f2f7` / successTint / easyTint —
each with its interval preview underneath ("<1 min", "1 day", "3 days", "6 days" — ALWAYS
computed live from the SRS engine for that card, never hardcoded). Grading persists the new
schedule and advances.

### 6c. Session complete

Centered 120px progress ring races to full; accent check pops in (~0.55s spring, 0.3s delay);
title "Round complete"; line "You cleared today's reviews. <Strongest deck> is holding strong."
(learn variant: "That's <deck> under way. <n> cards down."); three stat tiles: cards
reviewed / minutes (m:ss) / day streak (ticks up visibly if this session completed today);
primary "Done" (accent) + text button "Learn 5 more" (starts a 5-card learn micro-session if new
cards remain). One tasteful beat, then out. **No mascot, no fireworks.**

## 7. Retention surfaces

### 7.1 Reviews tab

Title "Reviews", subtitle "Keeping <city/country> fresh". Hero: 120px ring "12 / due now" +
"A quick 4-minute round keeps these from slipping." + "Start review" (accent). Stat tiles with
counts: **Due** (red) / **Learning** (orange) / **Mastered** (green). Per-deck strength list:
3-segment mini bar glyph (0–3 filled by deck strength) + deck name + due count — "shows what's
solid and what's slipping." Empty state (0 due): calm "Nothing due right now" + next-due time.

### 7.2 Progress tab

- **Streak card** (amber gradient on streakAmberTint): flickering flame + "6-day streak" +
  "Keep it alive — 3 min today does it" + 7-dot week row (M T W T F S S: filled amber check =
  done, outlined ring = today, faint = future/missed).
- Stat tiles: "84 words learned" / "62 minutes" / "3 decks going".
- **"<City> survival readiness"** card: 72px accent ring at N% + "You can handle food, greetings
  & directions. Nightlife's next." Readiness = learned coverage across the trip's selected
  scenarios; the copy names covered scenarios and the next gap. Reframes progress around the
  TRIP — no XP.

### 7.3 Notifications

Local notifications fire **only when reviews are actually due** ("12 cards are slipping") —
never a daily guilt-trip. Permission is requested after the first completed session, not at
launch.

## 8. Content & data model

### 8.1 Bundled catalog (`Content/` — schema the external pipeline targets)

- `Content/catalog.json` — `{ version, scenarios[], countries[], comingSoon[] }`. Country:
  `{ id, name, languageName, nativeLanguageName, accent, flagEmoji, decks[], bundles[] }`.
  Deck: `{ id, title, subtitle, scenario, icon (SF Symbol), cardsFile, cardCount, priceGBP }`.
  Bundle: `{ id, title, subtitle, deckIds[], priceGBP, popular }`.
- `Content/decks/<file>.json` — `{ deckId, cards: [{ id, english, target, pronunciation, audio,
  notes?, category? }] }` (exactly the anki-builder item shape).
- `Content/audio/<hash>.mp3` — one clip per card, referenced by filename.
- FIXTURE CAVEATS (v1 sample data, do not "fix"): deck contents are sliced from a Japanese
  textbook, so themes are approximate; France/Germany reuse the Japanese card files as
  placeholders until the pipeline ships real content.

### 8.2 SRS model (SM-2-style)

Per-card state: status (new/learning/review), easeFactor (start 2.5, floor 1.3), interval,
repetitions, dueDate, lapses. Grades: Again = lapse (repetitions→0, due in <1 min, ease −0.2);
Hard = ease −0.15 and the interval HOLDS for a learning card (a 1-day card stays at 1 day)
while a review card gets interval ×1.2 (rounded up); Good = SM-2 progression tuned so a young card
walks 1 day → 3 days → interval×ease; Easy = interval ×ease ×1.3, ease +0.15. The designed
previews for a typical young card MUST hold: Again "<1 min", Hard "1 day", Good "3 days",
Easy "6 days" (exact ladder pinned in the SRS task's spec + tests). "Mastered" = review card
with interval ≥ 21 days. Learn-mode first pass: correct ≈ Good, wrong ≈ Again. The engine is
pure Swift, fully unit-tested; UI always asks the engine for interval previews — never
hardcodes them.

### 8.3 Persisted user state (SwiftData, on-device)

Active trip (country id, duration weekend/week, selected scenarios, start date), owned pack ids +
owned bundle ids, per-card SRS rows keyed (deckId, cardId), per-day activity rows (date, cards
reviewed, seconds studied, wordsLearned) powering streaks/stats, notification-permission flag.

## 9. Browse tab (store — unmocked; build from this doc's design system)

Browse is the store: country sections → their scenario packs (price or "Owned") and bundles.
Design it with the established vocabulary: grouped white cards, accent tints of the country each
section belongs to, price pills, a "Restore purchases" row at the bottom. Owned decks live on
Home; Browse is for buying. Keep it simple and native — no new visual language.
