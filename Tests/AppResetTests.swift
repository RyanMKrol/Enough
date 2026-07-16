import SwiftData
import XCTest

@testable import Enough

@MainActor
class AppResetTests: XCTestCase {
  private let suiteName = "AppResetTests"

  override func tearDown() {
    super.tearDown()
    UserDefaults().removePersistentDomain(forName: suiteName)
  }

  private func makeContainer() throws -> ModelContainer {
    try PersistenceStack.container(inMemory: true)
  }

  func testWipeAllDeletesAllRecords() throws {
    let container = try makeContainer()
    let context = ModelContext(container)

    let trip = TripProfileRecord(
      countryId: "jp",
      duration: "week",
      scenarioIds: ["s1"],
      startDate: Date(),
      accentRawValue: "orange"
    )
    context.insert(trip)

    let entitlement = EntitlementRecord(
      productId: "d1",
      kind: "deck",
      grantedAt: Date()
    )
    context.insert(entitlement)

    let card = CardSRSRecord(
      deckId: "d1",
      cardId: "c1",
      statusRaw: "new"
    )
    context.insert(card)

    let activity = DailyActivityRecord(
      day: Date(),
      cardsReviewed: 10,
      cardsLearned: 5,
      secondsStudied: 600
    )
    context.insert(activity)

    try context.save()

    let userDefaults = UserDefaults(suiteName: suiteName)!
    userDefaults.set(3, forKey: AdjustableDateProvider.offsetKey)

    try AppReset.wipeAll(context: context, userDefaults: userDefaults)

    var tripDescriptor = FetchDescriptor<TripProfileRecord>()
    let trips = try context.fetch(tripDescriptor)
    XCTAssertTrue(trips.isEmpty)

    var entitlementDescriptor = FetchDescriptor<EntitlementRecord>()
    let entitlements = try context.fetch(entitlementDescriptor)
    XCTAssertTrue(entitlements.isEmpty)

    var cardDescriptor = FetchDescriptor<CardSRSRecord>()
    let cards = try context.fetch(cardDescriptor)
    XCTAssertTrue(cards.isEmpty)

    var activityDescriptor = FetchDescriptor<DailyActivityRecord>()
    let activities = try context.fetch(activityDescriptor)
    XCTAssertTrue(activities.isEmpty)

    XCTAssertNil(userDefaults.object(forKey: AdjustableDateProvider.offsetKey))
  }
}
