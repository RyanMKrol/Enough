# Enough — architecture contract (canonical names & signatures)

This doc pins the shared type names, directory layout, and key signatures that backlog tasks
build against, so 60+ atomic tasks built by independent cold agents compose into one app. Task
specs restate the signatures they touch; if a spec and this doc disagree, the SPEC wins (and the
divergence should be flagged in the worklog). Design/behavior lives in `design-spec.md`.

## Module layout (single app target `Enough` — directories are namespaces, no imports needed)

```
Sources/
  EnoughApp.swift          @main — builds AppServices + AppState, shows RootView
  App/                     AppState, RootView, MainShellView, tab enum, AppServices (DI)
  CoreKit/                 DateProvider + tiny shared utilities
  DesignSystem/            tokens + reusable visual components (no business logic)
  ContentKit/              content catalog models + ContentStore (read-only bundled data)
  Persistence/             SwiftData models ("...Record") + stores ("...Store")
  SRSKit/                  pure spaced-repetition logic (no SwiftData, no SwiftUI)
  Services/                app services gluing content + persistence + SRS to the UI
  Features/<Area>/         screens & screen-specific views (Onboarding, Home, DeckDetail,
                           Session, Reviews, Progress, Browse, Debug)
Tests/                     XCTest unit tests (single EnoughTests target)
Content/                   bundled catalog fixture (catalog.json, decks/, audio/) — data, not code
```

Conventions: **Swift 6 language mode with MainActor default isolation** (build settings:
`SWIFT_VERSION 6.0`, `SWIFT_APPROACHABLE_CONCURRENCY YES`, app target
`SWIFT_DEFAULT_ACTOR_ISOLATION MainActor`, test target `nonisolated`) — write straightforward
synchronous code; do NOT hand-annotate `@MainActor` on types (it's the default). iOS 18,
2-space indent, SwiftLint strict (line ≤ 130) + swift-format strict. Tests use **XCTest** (not
Swift Testing). UI state uses the `@Observable` macro (not ObservableObject) unless a spec says
otherwise. Persistence tests always use the in-memory container. No singletons except where
pinned below; dependencies flow through `AppServices`.

## House rules (Axiom-derived — every builder follows these)

**SwiftUI**
- View bodies are pure: no formatter creation, no filtering/sorting over stores, no throwing
  service calls in `body` — logic lives in the `@Observable` view model.
- View models are `@State`, created ONCE (init or `.onAppear`), never constructed in `body`;
  passed-in data is `let` (or `@Bindable` when `$` is needed) — never `@State var model` for
  parent-owned data.
- One `NavigationStack` per tab, owned by the tab's root view; never nested;
  `.navigationDestination` attaches to the ScrollView/stack root — NEVER inside `ForEach`/lazy
  content (it silently fails there).
- Anything tappable is a `Button` with a ButtonStyle — never bare `.onTapGesture`; every
  tappable element gets a ≥44×44pt hit area (`.frame(minWidth: 44, minHeight: 44)` +
  `.contentShape(Rectangle())`) even when drawn smaller.
- Animations are always value-bound (`withAnimation` or `.animation(_:value:)`; the value-less
  form is banned). Infinite loops start from an `.onAppear` state flip, respect
  `@Environment(\.accessibilityReduceMotion)` (static fallback), AND pause when their tab is
  hidden. Never `await` inside `withAnimation`.
- Fonts only via `EnoughFont` (semantic-style-backed); inline `.font(.system(size:))` is
  banned. Text-bearing frames use `minHeight`/`minWidth`, never fixed `height` — Dynamic Type
  must be able to grow controls (`Layout.buttonHeight` etc. are minimums).
- Formatters (`NumberFormatter`, `DateFormatter`) are `static let`, created once.
- Every `fullScreenCover` shows a visible close/X (it has no system dismiss gesture).

**Concurrency**
- No `actor` declarations anywhere — the app is one isolation domain (MainActor). No
  `Task.detached` (single pinned exception: the StoreKit `Transaction.updates` listener in
  T062), no `DispatchQueue`/GCD, no `Task {}` in view bodies — async work lives behind a
  synchronous model/service method that spawns `Task {}` internally only for genuinely async
  APIs.
- Never silence an isolation error with `@unchecked Sendable`, `nonisolated(unsafe)`, or
  `@preconcurrency` — restructure to stay on MainActor.
- Every `Task {}` handles thrown errors with `do/catch`.
- `Date()`/`Date.now` is banned outside `SystemDateProvider` — time flows through
  `DateProvider`/injected `now`.
- Never use `hashValue` for anything that must be stable across launches (it is per-process
  seeded) — use a stable byte-level hash (e.g. FNV-1a) instead.

**Persistence**
- Exactly ONE `ModelContainer`, built by `PersistenceStack` inside `AppServices`; `@Query` and
  the `.modelContainer(for:)` view modifier are banned (each silently creates a second stack).
- One shared main-thread `ModelContext` owned by `AppServices`; stores, contexts, and fetched
  records never enter `Task`/actors/background queues — convert to value types (`SRSState`,
  `DeckProgress`) at the service seam.
- Every store mutation ends with explicit `try context.save()` (hand-created contexts have
  autosave OFF — never rely on it).
- `@Model` = `final class` with explicit memberwise `init`; no `@Relationship` anywhere in this
  app; no `@Attribute(.unique)` (its upsert-on-save semantics mask bugs and it's
  CloudKit-incompatible) — uniqueness is enforced by fetch-before-insert upserts in stores.
- `#Predicate` bodies contain only stored-property comparisons against pre-hoisted `let`
  values — no function calls, no `Set.contains`, no force-unwraps.

**Testing**
- `@MainActor` goes on individual test METHODS that touch app types — never on the XCTestCase
  class (collides with XCTest's nonisolated overrides under default isolation).
- Banned in tests: `sleep`/`Task.sleep`, timed `XCTestExpectation` waits, real clocks
  (`Date()`), `UserDefaults.standard` (use `UserDefaults(suiteName:)` + teardown), `try!`/`as!`
  on SUT values (use `XCTUnwrap`), shared/static containers.
- Fresh in-memory container per test method via `PersistenceStack.container(inMemory: true)`;
  the `ModelContainer(for:)` convenience initializer is banned in tests (it hits disk).

**Money**
- Every user-facing price string flows through `PurchaseProviding.displayPrice` /
  `PricingCalculator` — a `grep for "£" in Sources/Features/` must return nothing.

## CoreKit

```swift
protocol DateProvider { var now: Date { get } }
struct SystemDateProvider: DateProvider            // Date()
final class AdjustableDateProvider: DateProvider   // system time + persisted day offset
// AdjustableDateProvider: init(userDefaults: UserDefaults = .standard),
//   var dayOffset: Int (persisted under key "debug.dayOffset"), now = system + offset days
```

## DesignSystem (all tokens from design-spec.md §1)

```swift
enum EnoughColor           // static let canvas, surface, insetSurface, label, secondaryText,
                           // tertiaryText, faintText, hairline, linkBlue, successGreen,
                           // successTint, successDeep, easyBlue, easyTint, streakAmber,
                           // streakAmberTint, graphite ... (SwiftUI Color, hex-initialised)
enum AccentTheme: String, CaseIterable   // case japan, france, germany
                           // var accent: Color; var tint: Color; var deep: Color
                           // init?(rawValue:) matches catalog "accent" strings
// EnvironmentValues.accentTheme (default .japan) via extension + @Entry
enum EnoughFont            // static funcs: largeTitle(), wordmark(), screenTitle(), headline(),
                           // subEmphasis(), body(), subhead(), footnote(), eyebrow() -> Font
                           // Backed by SEMANTIC text styles (+ weight) so Dynamic Type scales:
                           // largeTitle→.largeTitle bold, screenTitle→.title bold, 22→.title2,
                           // 20→.title3, body→.body, subhead→.subheadline, footnote→.footnote,
                           // eyebrow→.caption semibold. Only wordmark() is truly fixed (44pt).
                           // Odd display sizes (34/36 card phrases) via @ScaledMetric at call site.
enum Layout                // static let buttonRadius: CGFloat = 16, cardRadius = 20, heroRadius = 26,
                           // buttonHeight = 54, screenHPad = 22, sectionGap = 18 ... (see spec)
enum Motion                // static let bobDuration = 4.0, ringFill = 1.2, barGrow = 1.0,
                           // checkPop = 0.5, shake = 0.5, cardSwap = 0.35, flicker = 2.2,
                           // popSpring = Animation.spring(...) etc.
struct PrimaryButtonStyle: ButtonStyle    // init(background: Color = EnoughColor.graphite)
struct TintedButtonStyle: ButtonStyle     // accent-tinted secondary
struct TextLinkButtonStyle: ButtonStyle   // linkBlue text button
struct ScenarioChip: View     // init(title: String, isSelected: Bool, action: () -> Void)
struct MetaChip: View         // translucent white pill, init(text: String)
struct EyebrowLabel: View     // uppercase tracked label, init(_ text: String)
struct AnimatedProgressBar: View  // init(progress: Double, tint: Color) — grows on appear
struct ProgressRing: View     // init(progress: Double, size: CGFloat, lineWidth: CGFloat = 6,
                              //      tint: Color, showsPercent: Bool = true) — fills on appear
struct PulsingAudioButton: View  // init(size: CGFloat = 60, isPulsing: Bool = true, action: () -> Void)
                                 // speaker icon; ripple-once on tap via internal trigger
struct CheckPopView: View     // init(size: CGFloat, color: Color) — pops on appear
struct ShakeEffect: GeometryEffect  // init(shakes: CGFloat) — usable via .modifier
struct BottomResultSheet<Content: View>: View  // slides up from bottom, radius 24 top, tinted bg
struct StreakPill: View       // init(count: Int) — white pill + flickering flame
struct CardStackHero: View    // welcome premium-panel stack (fixed content per design-spec §2.1)
enum GradeChoice: CaseIterable        // case again, hard, good, easy (display-level, NOT SRSKit)
                                      // var title: String; var fill: Color; var textColor: Color
struct GradeButtonRow: View   // init(previews: [GradeChoice: String], onGrade: (GradeChoice) -> Void)
```

## ContentKit (Codable mirrors of Content/catalog.json — see design-spec.md §8.1)

```swift
struct ContentCatalog: Codable   // version, scenarios: [ScenarioInfo], countries: [CountryInfo],
                                 // comingSoon: [String]
struct ScenarioInfo: Codable, Identifiable   // id, title
struct CountryInfo: Codable, Identifiable    // id, name, languageName, nativeLanguageName,
                                             // accent, flagEmoji, decks: [DeckInfo], bundles: [BundleInfo]
struct DeckInfo: Codable, Identifiable       // id, title, subtitle, scenario, icon, cardsFile,
                                             // cardCount, priceGBP: Double
struct BundleInfo: Codable, Identifiable     // id, title, subtitle, deckIds, priceGBP, popular
struct DeckCards: Codable                    // deckId, cards: [CardContent]
struct CardContent: Codable, Identifiable    // id, english, target, pronunciation, audio,
                                             // notes: String?, category: String?
final class ContentStore {
  init(bundle: Bundle = .main)
  func catalog() throws -> ContentCatalog          // cached after first load
  func cards(forDeck deckId: String) throws -> [CardContent]
  func audioURL(forFile name: String) -> URL?      // Content/audio/<name>
  func country(_ id: String) throws -> CountryInfo
  func deck(_ id: String) throws -> DeckInfo       // searches all countries
}
```

Note: `Content/` is bundled as a **folder reference** resource of the app target (added to
`project.yml` by T012), so paths inside the bundle are `Content/catalog.json` etc.

## Persistence (SwiftData; every store takes a ModelContext)

```swift
enum PersistenceStack {
  static let models: [any PersistentModel.Type]      // all four Record types
  static func container(inMemory: Bool = false) throws -> ModelContainer
}
@Model final class TripProfileRecord   // countryId, duration ("weekend"|"week"), scenarioIds,
                                       // startDate, accentRawValue, isActive
@Model final class EntitlementRecord   // productId (deck or bundle id), kind ("deck"|"bundle"),
                                       // grantedAt
@Model final class CardSRSRecord       // deckId, cardId, statusRaw ("new"|"learning"|"review"),
                                       // easeFactor, intervalDays, repetitions, lapses, dueAt,
                                       // lastReviewedAt?
@Model final class DailyActivityRecord // day (startOfDay Date), cardsReviewed, cardsLearned,
                                       // secondsStudied
final class TripStore        { init(context: ModelContext) }   // activeTrip(), save/replace, dayNumber(now:)
final class EntitlementStore { init(context: ModelContext) }   // ownedDeckIds(catalog:) resolves bundles→decks,
                                                               // grant(productId:kind:), revoke(productId:) (no-op
                                                               // if absent — refunds/revocations), isOwned(deckId:catalog:), reset()
final class CardSRSStore     { init(context: ModelContext) }   // record(deckId:cardId:), upsert(_:),
                                                               // records(forDeck:), dueRecords(now:ownedDeckIds:), reset()
final class ActivityStore    { init(context: ModelContext) }   // record(for day:), addActivity(...), all(), reset()
```

## SRSKit (pure — Foundation only)

```swift
enum SRSGrade: String, CaseIterable      // again, hard, good, easy
enum CardStatus: String                  // new, learning, review
struct SRSState: Equatable               // status, easeFactor (2.5 start, 1.3 floor),
                                         // intervalDays: Double, repetitions, lapses, dueAt: Date?
enum SRSEngine {
  static func apply(_ grade: SRSGrade, to state: SRSState, now: Date) -> SRSState
  static func previewInterval(_ grade: SRSGrade, for state: SRSState) -> TimeInterval
  static func previewLabel(_ grade: SRSGrade, for state: SRSState) -> String  // "<1 min", "3 days"
  static func isDue(_ state: SRSState, now: Date) -> Bool
  static func isMastered(_ state: SRSState) -> Bool     // review && intervalDays >= 21
}
enum SRSQueueBuilder {
  static func reviewQueue(from: [(cardId: String, deckId: String, state: SRSState)], now: Date, limit: Int?) -> [...]
  static func learnBatch(newCardIds: [String], size: Int = 12) -> [String]
}
struct SessionCard { let deckId: String; let cardId: String; var state: SRSState }
enum SessionMode { case learn, review, practice }
struct SessionSummary { cardsCompleted, correctCount, duration: TimeInterval, mode }
final class SessionEngine {   // pure state machine; owns requeue-on-miss
  init(mode: SessionMode, cards: [SessionCard], now: () -> Date)
  var current: SessionCard? ; var progress: (done: Int, total: Int)
  func submitMultipleChoice(correct: Bool) -> SRSGrade?   // learn/practice; nil in practice (no SRS write)
  func submitGrade(_ grade: SRSGrade)                     // review mode
  func advance()                                          // move to next card
  var isComplete: Bool ; func summary() -> SessionSummary
  var gradedResults: [(SessionCard, SRSGrade)]            // what StudyService commits
}
```

## Services

```swift
final class DeckProgressService {  // init(content: ContentStore, srsStore: CardSRSStore,
                                   //      entitlements: EntitlementStore, dateProvider: DateProvider)
  struct DeckProgress { deckId, total, learned, newCount, learning, mastered, dueNow, strength: Int /*0–3*/ }
  func progress(forDeck id: String) throws -> DeckProgress
  func totalDue() throws -> Int ; func totals() throws -> (due: Int, learning: Int, mastered: Int)
  func wordsLearned() throws -> Int
}
final class StudyService {         // init(content:, srsStore:, activityStore:, dateProvider:)
  func makeLearnSession(deckId: String, size: Int = 12) throws -> SessionEngine
  func makeReviewSession() throws -> SessionEngine          // all due, owned decks
  func makePracticeSession(deckId: String) throws -> SessionEngine
  func makeLearnMoreSession(size: Int = 5) throws -> SessionEngine
  func commit(_ engine: SessionEngine) throws               // SRS rows + DailyActivity
}
enum PricingCalculator {           // pure; £ formatting via NumberFormatter (en_GB)
  static func price(_ gbp: Double) -> String                 // "£2.49"
  static func bundleSavings(_ bundle: BundleInfo, in country: CountryInfo) -> Double
  static func planTotal(selectedBundle: BundleInfo?, extraDeckIds: Set<String>, country: CountryInfo) -> Double
  static func summaryLine(...) -> String                     // "Weekend · 3 packs"
}
enum PurchaseOutcome { case success, cancelled, pending }   // StoreKit 2's real result shape:
                                    // user-cancel is a NORMAL return (never an error path);
                                    // .pending (Ask to Buy) grants nothing — the entitlement
                                    // arrives later via the updates listener.
protocol PurchaseProviding: AnyObject {   // shaped like StoreKit 2
  var ownedProductIds: Set<String> { get }
  func purchase(productId: String, kind: EntitlementKind) async throws -> PurchaseOutcome
  func restorePurchases() async throws
  func displayPrice(productId: String) -> String?   // localized store price; stub falls back
                                                    // to PricingCalculator's catalog price
  func addObserver(_ handler: @escaping () -> Void) // MULTICAST — never a single settable
                                                    // closure (a second subscriber must not
                                                    // silently replace the first)
}
enum EntitlementKind: String { case deck, bundle }
final class StubPurchaseService: PurchaseProviding   // grants instantly via EntitlementStore;
                                                     // always returns .success
final class AudioService {          // init(content: ContentStore); AVAudioSession .playback
                                    // + [.duckOthers]; session activated at session start
                                    // (resetAutoPlay), deactivated by sessionEnded();
                                    // interruption observer stops playback; NO
                                    // AVAudioPlayerDelegate (off-main callbacks)
  func play(fileName: String)      // stops any current clip, plays this one
  func autoPlayOnce(cardId: String, fileName: String)   // once per cardId per session-screen
  func resetAutoPlay()             // called when a session starts (activates the session)
  func sessionEnded()              // stop + setActive(false, .notifyOthersOnDeactivation)
}
final class StatsService {          // init(activityStore:, dateProvider:)
  func currentStreak() throws -> Int
  func weekDots() throws -> [DayDot]      // Mon..Sun: .done/.today/.upcoming/.missed
  func totalMinutes() throws -> Int ; func markTodayComplete(...) via ActivityStore
}
struct ReadinessCalculator { ... }  // readiness(for trip, progress) -> (percent: Int, line: String)
final class NotificationsService { // schedule/cancel review-due notification; wraps UNUserNotificationCenter
final class DemoSeeder { ... }      // writes the full demo fixture (design-spec mock state)
enum AppReset { static func wipeAll(...) }
```

## App shell

```swift
@Observable final class AppState {  // phase: .onboarding | .main ; activeAccent: AccentTheme
                                    // init(services: AppServices) reads TripStore
  func completeOnboarding(trip: ...) ; func startNewTrip()
}
final class AppServices {           // built once in EnoughApp; passed via .environment
  let dateProvider, contentStore, container: ModelContainer,
      tripStore, entitlementStore, cardSRSStore, activityStore,
      purchase: PurchaseProviding, audio, study, deckProgress, stats, notifications
  static func live() -> AppServices ; static func preview() -> AppServices  // in-memory
}
// EnvironmentValues.services: AppServices via @Entry (default .preview())
struct RootView: View               // switches AppState.phase; injects accentTheme
enum EnoughTab: String, CaseIterable { case learn, reviews, progress, browse }
struct LiquidGlassTabBar: View      // init(selection: Binding<EnoughTab>)
struct MainShellView: View          // ZStack: selected tab screen + floating tab bar
```

## Feature screens (each in its own dir; names pinned)

`OnboardingFlowView` + `OnboardingDraft` (@Observable: country?, duration, scenarios, plan
selections) · `WelcomeView` · `CountryPickerView` · `TripShapeView` · `PlanView` (+`BundleRowView`,
`PackChecklistRow`, `PlanViewModel`) · `HomeView` (+`ContinueCard`, `ReviewsBanner`, `DeckListRow`)
· `DeckDetailView` · `MCSessionView` (+`MCQuestionHeader`, `AnswerRow`, `MCSessionViewModel`) ·
`ReviewSessionView` (+`FlashcardView`, `ReviewSessionViewModel`) · `SessionCompleteView` ·
`ReviewsTabView` · `ProgressTabView` (+`StreakCard`, `WeekDotsRow`) · `BrowseView` ·
`DebugMenuView` (sections; entries registered per debug task).

## Debug menu (god mode)

`DebugMenuView` opens via device shake anywhere in the main shell, or launch argument
`-debug-menu`. Launch argument `-demo-state` (checked in `EnoughApp` before first render) wipes
and seeds the demo fixture — used by `build_run.sh` visual verification. Each debug setting is a
row registered in `DebugMenuView`'s static section list by its own task.
