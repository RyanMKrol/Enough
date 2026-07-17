import SwiftData
import XCTest

@testable import Enough

@MainActor
final class ProgressViewModelTests: XCTestCase {
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
      stats: stats,
      notifications: NotificationsService(center: NoopNotificationCenter())
    )
  }

  func testRefreshWithNoActiveTripLeavesReadinessAndDestinationEmpty() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)

    let viewModel = ProgressViewModel(services: services)
    viewModel.refresh()

    XCTAssertEqual(viewModel.streak, 0)
    XCTAssertEqual(viewModel.wordsLearned, 0)
    XCTAssertEqual(viewModel.readinessPercent, 0)
    XCTAssertEqual(viewModel.readinessLine, "")
    XCTAssertEqual(viewModel.destination, "")
  }

  func testRefreshWithActiveTripSetsDestinationAndCountsOwnedDecks() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let services = try makeServices(now: now)
    try services.tripStore.saveNewTrip(
      countryId: "japan", duration: "weekend", scenarioIds: [], accentRawValue: "japan",
      startDate: now
    )
    try services.entitlementStore.grant(productId: "jp-greetings", kind: "deck", now: now)

    let cardIds = try services.contentStore.cards(forDeck: "jp-greetings").map(\.id)
    for cardId in cardIds.prefix(1) {
      try services.cardSRSStore.upsert(
        deckId: "jp-greetings", cardId: cardId, statusRaw: "review", easeFactor: 2.5,
        intervalDays: 8, repetitions: 1, lapses: 0, dueAt: now, lastReviewedAt: nil
      )
    }

    let viewModel = ProgressViewModel(services: services)
    viewModel.refresh()

    XCTAssertEqual(viewModel.destination, "Tokyo")
    XCTAssertEqual(viewModel.decksGoing, 1)
  }

  func testRefreshWhenContentStoreCatalogFailsFallsBackToEmptyState() throws {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    context.autosaveEnabled = false

    let dateProvider = FixedDateProvider(now: now)
    let emptyBundle = try makeEmptyBundle()
    let contentStore = ContentStore(bundle: emptyBundle)
    let tripStore = TripStore(context: context)
    let entitlementStore = EntitlementStore(context: context)
    let cardSRSStore = CardSRSStore(context: context)
    let activityStore = ActivityStore(context: context)
    let purchase = StubPurchaseService(entitlements: entitlementStore, catalog: nil)
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
    let services = AppServices(
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

    let viewModel = ProgressViewModel(services: services)
    viewModel.refresh()

    XCTAssertEqual(viewModel.decksGoing, 0)
    XCTAssertEqual(viewModel.readinessPercent, 0)
    XCTAssertEqual(viewModel.readinessLine, "")
    XCTAssertEqual(viewModel.destination, "")
  }

  private func makeEmptyBundle() throws -> Bundle {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(
      "progress-vm-empty-fixture-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    return try XCTUnwrap(Bundle(path: root.path))
  }
}
