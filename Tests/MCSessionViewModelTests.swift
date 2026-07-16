import SwiftData
import XCTest

@testable import Enough

@MainActor
final class MCSessionViewModelTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private func makeServices(now: Date, bundle: Bundle = .main) throws -> AppServices {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let dateProvider = FixedDateProvider(now: now)
    let contentStore = ContentStore(bundle: bundle)
    let tripStore = TripStore(context: context)
    let entitlementStore = EntitlementStore(context: context)
    let cardSRSStore = CardSRSStore(context: context)
    let activityStore = ActivityStore(context: context)
    let catalog = try? contentStore.catalog()
    let purchase = StubPurchaseService(entitlements: entitlementStore, catalog: catalog)
    let audio = AudioService(content: contentStore)
    let study = StudyService(
      content: contentStore, srsStore: cardSRSStore, activityStore: activityStore,
      entitlements: entitlementStore, dateProvider: dateProvider
    )
    let deckProgress = DeckProgressService(
      content: contentStore, srsStore: cardSRSStore, entitlements: entitlementStore,
      dateProvider: dateProvider
    )
    let stats = StatsService(activityStore: activityStore, dateProvider: dateProvider)

    return AppServices(
      dateProvider: dateProvider,
      contentStore: contentStore,
      container: container,
      tripStore: tripStore,
      entitlementStore: entitlementStore,
      cardSRSStore: cardSRSStore,
      activityStore: activityStore,
      purchase: purchase,
      audio: audio,
      study: study,
      deckProgress: deckProgress,
      stats: stats,
      notifications: NotificationsService(center: NoopNotificationCenter())
    )
  }

  // Builds a scratch on-disk "bundle" (a plain directory laid out like Content/) so the
  // < 4 cards fallback path can be exercised without a real fixture deck that small.
  private func fixtureCard(id: String, english: String) -> [String: Any] {
    [
      "id": id, "english": english, "target": "T-\(id)", "pronunciation": "p-\(id)",
      "audio": "\(id).mp3",
    ]  // swiftlint:disable:previous trailing_comma
  }

  private func fixtureDeckEntry(id: String, cardsFile: String, cardCount: Int) -> [String: Any] {
    [
      "id": id, "title": id, "subtitle": "s", "scenario": "s", "icon": "star",
      "cardsFile": cardsFile, "cardCount": cardCount, "priceGBP": 1.0,
    ]  // swiftlint:disable:previous trailing_comma
  }

  private func makeSmallDeckBundle() throws -> Bundle {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "mc-session-fixture-\(UUID().uuidString)")
    let decksDir = root.appendingPathComponent("Content/decks")
    try FileManager.default.createDirectory(at: decksDir, withIntermediateDirectories: true)

    let decks = [
      fixtureDeckEntry(id: "small-deck", cardsFile: "decks/small-deck.json", cardCount: 2),
      fixtureDeckEntry(id: "big-deck", cardsFile: "decks/big-deck.json", cardCount: 5),
    ]  // swiftlint:disable:previous trailing_comma
    let country: [String: Any] = [
      "id": "testland", "name": "Testland", "languageName": "Testish",
      "nativeLanguageName": "Testish", "accent": "japan", "flagEmoji": "🏳️",
      "decks": decks, "bundles": [],
    ]  // swiftlint:disable:previous trailing_comma
    let catalog: [String: Any] = [
      "version": 1, "scenarios": [], "countries": [country], "comingSoon": [],
    ]  // swiftlint:disable:previous trailing_comma

    let smallDeckCards = [
      fixtureCard(id: "s1", english: "Hello"),
      fixtureCard(id: "s2", english: "Goodbye"),
    ]  // swiftlint:disable:previous trailing_comma
    let smallDeck: [String: Any] = ["deckId": "small-deck", "cards": smallDeckCards]

    let bigDeckCards = (0..<5).map { fixtureCard(id: "b\($0)", english: "Big \($0)") }
    let bigDeck: [String: Any] = ["deckId": "big-deck", "cards": bigDeckCards]

    try JSONSerialization.data(withJSONObject: catalog).write(
      to: root.appendingPathComponent("Content/catalog.json"))
    try JSONSerialization.data(withJSONObject: smallDeck).write(
      to: decksDir.appendingPathComponent("small-deck.json"))
    try JSONSerialization.data(withJSONObject: bigDeck).write(
      to: decksDir.appendingPathComponent("big-deck.json"))

    guard let bundle = Bundle(path: root.path) else {
      throw ContentStoreError.missingResource(root.path)
    }
    return bundle
  }

  func testOptionsAreDeterministicAcrossSeparatelyConstructedViewModels() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let servicesA = try makeServices(now: now)
    let servicesB = try makeServices(now: now)

    let engineA = try servicesA.study.makeLearnSession(deckId: "jp-greetings", size: 5)
    let engineB = try servicesB.study.makeLearnSession(deckId: "jp-greetings", size: 5)

    let vmA = MCSessionViewModel(engine: engineA, services: servicesA)
    let vmB = MCSessionViewModel(engine: engineB, services: servicesB)

    XCTAssertEqual(vmA.options.count, 4)
    XCTAssertEqual(Set(vmA.options).count, 4)

    let cards = try servicesA.contentStore.cards(forDeck: "jp-greetings")
    let currentEnglish = cards.first(where: { $0.id == vmA.currentCardId })?.english
    XCTAssertNotNil(currentEnglish)
    XCTAssertTrue(vmA.options.contains(currentEnglish!))

    XCTAssertEqual(vmA.options, vmB.options)
  }

  func testFallbackToOtherDecksWhenDeckHasFewerThanFourCards() throws {
    let bundle = try makeSmallDeckBundle()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now, bundle: bundle)

    let engine = try services.study.makePracticeSession(deckId: "small-deck")
    let vm = MCSessionViewModel(engine: engine, services: services)

    XCTAssertEqual(vm.options.count, 4)
    XCTAssertEqual(Set(vm.options).count, 4)
  }

  func testProgressTextAdvancesOnlyAfterAnswerSubmitted() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    let engine = try services.study.makeLearnSession(deckId: "jp-greetings", size: 3)
    let vm = MCSessionViewModel(engine: engine, services: services)

    XCTAssertEqual(vm.progressText, "0/3")

    let cards = try services.contentStore.cards(forDeck: "jp-greetings")
    let currentEnglish = cards.first(where: { $0.id == vm.currentCardId })!.english
    vm.select(option: currentEnglish)

    XCTAssertEqual(vm.progressText, "1/3")
  }

  func testWrongAnswerRequeuesCardLaterInSession() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    let engine = try services.study.makeLearnSession(deckId: "jp-greetings", size: 3)
    let vm = MCSessionViewModel(engine: engine, services: services)

    let cards = try services.contentStore.cards(forDeck: "jp-greetings")
    let firstCardId = vm.currentCardId!
    let firstCardEnglish = cards.first(where: { $0.id == firstCardId })!.english
    let wrongOption = vm.options.first(where: { $0 != firstCardEnglish })!

    vm.select(option: wrongOption)
    if case .incorrect = vm.resultSheet {
    } else {
      XCTFail("expected incorrect result sheet")
    }

    vm.advance()
    vm.advance()
    vm.advance()

    XCTAssertEqual(vm.currentCardId, firstCardId)
  }

  func testCloseAndCommitPersistsOnlyGradedResults() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    let engine = try services.study.makeLearnSession(deckId: "jp-greetings", size: 3)
    let vm = MCSessionViewModel(engine: engine, services: services)

    let cards = try services.contentStore.cards(forDeck: "jp-greetings")
    let firstCardId = vm.currentCardId!
    let firstCardEnglish = cards.first(where: { $0.id == firstCardId })!.english
    vm.select(option: firstCardEnglish)

    vm.closeAndCommit()

    let records = try services.cardSRSStore.records(forDeck: "jp-greetings")
    XCTAssertEqual(records.count, 1)
    XCTAssertEqual(records.first?.cardId, firstCardId)
  }
}
