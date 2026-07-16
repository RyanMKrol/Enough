import SwiftData
import XCTest

@testable import Enough

@MainActor
class HomeViewModelTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private func makeServices(now: Date) throws -> AppServices {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let dateProvider = FixedDateProvider(now: now)
    let contentStore = ContentStore()
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
      stats: stats
    )
  }

  func testSubtitleMathForWeekendTripInJapan() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let services = try makeServices(now: now)
    try services.tripStore.saveNewTrip(
      countryId: "japan", duration: "weekend", scenarioIds: [], accentRawValue: "japan",
      startDate: startDate
    )

    let viewModel = HomeViewModel(services: services)
    viewModel.reload()

    XCTAssertEqual(viewModel.subtitle, "Weekend in Tokyo · Day 2")
  }

  func testContinueDeckPicksPartiallyLearnedDeckOverFullyLearned() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    try services.tripStore.saveNewTrip(
      countryId: "japan", duration: "weekend", scenarioIds: [], accentRawValue: "japan",
      startDate: now
    )

    try services.entitlementStore.grant(productId: "jp-greetings", kind: "deck", now: now)
    try services.entitlementStore.grant(productId: "jp-ordering-food", kind: "deck", now: now)

    let greetingsCardIds = try services.contentStore.cards(forDeck: "jp-greetings").map(\.id)
    for cardId in greetingsCardIds {
      try services.cardSRSStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review", easeFactor: 2.5,
        intervalDays: 8, repetitions: 1, lapses: 0, dueAt: now, lastReviewedAt: nil
      )
    }

    let eatingOutCardIds = try services.contentStore.cards(forDeck: "jp-ordering-food").map(\.id)
    for cardId in eatingOutCardIds.prefix(2) {
      try services.cardSRSStore.upsert(
        deckId: "jp-ordering-food", cardId: cardId, statusRaw: "review", easeFactor: 2.5,
        intervalDays: 8, repetitions: 1, lapses: 0, dueAt: now, lastReviewedAt: nil
      )
    }

    let viewModel = HomeViewModel(services: services)
    viewModel.reload()

    XCTAssertEqual(viewModel.continueDeck?.deck.id, "jp-ordering-food")
  }

  func testContinueDeckPicksFirstOwnedDeckWhenAllUntouched() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    try services.tripStore.saveNewTrip(
      countryId: "japan", duration: "weekend", scenarioIds: [], accentRawValue: "japan",
      startDate: now
    )

    try services.entitlementStore.grant(productId: "jp-greetings", kind: "deck", now: now)
    try services.entitlementStore.grant(productId: "jp-ordering-food", kind: "deck", now: now)

    let viewModel = HomeViewModel(services: services)
    viewModel.reload()

    let catalog = try services.contentStore.catalog()
    let japanDecks = catalog.countries.first(where: { $0.id == "japan" })?.decks ?? []
    let firstOwnedId = japanDecks.first(where: {
      $0.id == "jp-greetings" || $0.id == "jp-ordering-food"
    })?.id

    XCTAssertEqual(viewModel.continueDeck?.deck.id, firstOwnedId)
    if case .new = viewModel.deckRows.first(where: { $0.deck.id == firstOwnedId })?.status {
    } else {
      XCTFail("expected first owned deck row to be new")
    }
  }

  func testContinueDetailLineEstimatesMinutesFromRemainingCards() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    try services.tripStore.saveNewTrip(
      countryId: "japan", duration: "weekend", scenarioIds: [], accentRawValue: "japan",
      startDate: now
    )

    try services.entitlementStore.grant(productId: "jp-greetings", kind: "deck", now: now)
    let cardIds = try services.contentStore.cards(forDeck: "jp-greetings").map(\.id)
    XCTAssertGreaterThanOrEqual(cardIds.count, 22)
    let total = cardIds.count
    let learnedCount = total - 22

    for cardId in cardIds.prefix(learnedCount) {
      try services.cardSRSStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review", easeFactor: 2.5,
        intervalDays: 8, repetitions: 1, lapses: 0, dueAt: now, lastReviewedAt: nil
      )
    }

    let viewModel = HomeViewModel(services: services)
    viewModel.reload()

    XCTAssertEqual(
      viewModel.continueDetailLine, "\(learnedCount) of \(total) cards · about 9 min left")
  }

  func testReviewsBannerVisibilityTracksDueCount() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    try services.tripStore.saveNewTrip(
      countryId: "japan", duration: "weekend", scenarioIds: [], accentRawValue: "japan",
      startDate: now
    )

    let viewModelNoDue = HomeViewModel(services: services)
    viewModelNoDue.reload()
    XCTAssertEqual(viewModelNoDue.dueCount, 0)

    try services.entitlementStore.grant(productId: "jp-greetings", kind: "deck", now: now)
    let cardIds = try services.contentStore.cards(forDeck: "jp-greetings").map(\.id)
    for cardId in cardIds.prefix(3) {
      try services.cardSRSStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review", easeFactor: 2.5,
        intervalDays: 8, repetitions: 1,
        lapses: 0, dueAt: now.addingTimeInterval(-3600), lastReviewedAt: nil
      )
    }

    let viewModelWithDue = HomeViewModel(services: services)
    viewModelWithDue.reload()
    XCTAssertGreaterThan(viewModelWithDue.dueCount, 0)
  }
}
