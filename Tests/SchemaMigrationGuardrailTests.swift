import SwiftData
import XCTest

@testable import Enough

// When adding `EnoughSchemaV2`: never edit V1's models; add the new schema + a MigrationStage to
// EnoughMigrationPlan, then EXTEND this test to seed with V1 and open with the full plan —
// simulator reinstalls hide broken migrations; this test is the only automated coverage.
@MainActor
final class SchemaMigrationGuardrailTests: XCTestCase {
  private var storeDirectory: URL!

  override func setUp() async throws {
    try await super.setUp()
    storeDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent(
        "SchemaMigrationGuardrailTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
  }

  override func tearDown() async throws {
    if let storeDirectory {
      try? FileManager.default.removeItem(at: storeDirectory)
    }
    storeDirectory = nil
    try await super.tearDown()
  }

  func testStoreCreatedWithV1ReopensCleanlyWithSamePlan() throws {
    let storeURL = storeDirectory.appendingPathComponent("Enough.store")

    var container: ModelContainer? = try PersistenceStack.container(at: storeURL)
    let context = ModelContext(container!)

    let startDate = Date(timeIntervalSince1970: 1_700_000_000)
    context.insert(
      TripProfileRecord(
        countryId: "japan",
        duration: "week",
        scenarioIds: ["greetings"],
        startDate: startDate,
        accentRawValue: "japan",
        isActive: true
      ))
    context.insert(
      EntitlementRecord(productId: "japan-greetings", kind: "deck", grantedAt: startDate))
    context.insert(
      CardSRSRecord(
        deckId: "japan-greetings",
        cardId: "card-1",
        statusRaw: "new"
      ))
    context.insert(
      DailyActivityRecord(day: startDate, cardsReviewed: 1, cardsLearned: 1, secondsStudied: 60))
    try context.save()

    container = nil

    let reopenedContainer = try PersistenceStack.container(at: storeURL)
    let reopenedContext = ModelContext(reopenedContainer)

    let trips = try reopenedContext.fetch(FetchDescriptor<TripProfileRecord>())
    XCTAssertEqual(trips.count, 1)
    XCTAssertEqual(trips.first?.countryId, "japan")

    let entitlements = try reopenedContext.fetch(FetchDescriptor<EntitlementRecord>())
    XCTAssertEqual(entitlements.count, 1)
    XCTAssertEqual(entitlements.first?.productId, "japan-greetings")

    let cards = try reopenedContext.fetch(FetchDescriptor<CardSRSRecord>())
    XCTAssertEqual(cards.count, 1)
    XCTAssertEqual(cards.first?.cardId, "card-1")

    let activity = try reopenedContext.fetch(FetchDescriptor<DailyActivityRecord>())
    XCTAssertEqual(activity.count, 1)
    XCTAssertEqual(activity.first?.cardsReviewed, 1)
  }
}
