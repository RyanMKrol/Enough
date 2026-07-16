import SwiftData
import XCTest

@testable import Enough

@MainActor
final class DemoSeederTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private func makeContext() throws -> ModelContext {
    let container = try PersistenceStack.container(inMemory: true)
    return ModelContext(container)
  }

  func testSeedProducesTheDesignMockFixture() throws {
    let context = try makeContext()
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    try DemoSeeder.seed(content: content, context: context, now: now)

    let dateProvider = FixedDateProvider(now: now)
    let entitlementStore = EntitlementStore(context: context)
    let srsStore = CardSRSStore(context: context)
    let tripStore = TripStore(context: context)
    let deckProgress = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlementStore,
      dateProvider: dateProvider)
    let activityStore = ActivityStore(context: context)
    let stats = StatsService(activityStore: activityStore, dateProvider: dateProvider)

    // (a) 12 cards due now
    XCTAssertEqual(try deckProgress.totalDue(), 12)

    // (b) 6-day streak
    XCTAssertEqual(try stats.currentStreak(), 6)

    // (c) day 2 of the trip
    XCTAssertEqual(try tripStore.dayNumber(now: now), 2)

    // (d) owned decks resolved from the jp-weekend bundle
    let owned = try entitlementStore.ownedDeckIds(catalog: try content.catalog())
    XCTAssertEqual(owned, ["jp-greetings", "jp-ordering-food", "jp-at-the-bar"])

    // (e) seeding twice does not duplicate rows
    try DemoSeeder.seed(content: content, context: context, now: now)

    let greetingsRecords = try srsStore.records(forDeck: "jp-greetings")
    let orderingRecords = try srsStore.records(forDeck: "jp-ordering-food")
    XCTAssertEqual(greetingsRecords.count + orderingRecords.count, 38)

    let activityRecords = try activityStore.all()
    XCTAssertEqual(activityRecords.count, 6)
  }
}
