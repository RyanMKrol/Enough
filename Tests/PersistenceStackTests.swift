import SwiftData
import XCTest

@testable import Enough

@MainActor
class PersistenceStackTests: XCTestCase {
  func testContainerInMemoryDoesNotThrowAndModelsCountIsFour() throws {
    let container = try PersistenceStack.container(inMemory: true)
    XCTAssertNotNil(container)
    XCTAssertEqual(PersistenceStack.models.count, 4)
  }

  func testSchemaV1ContainsAllFourModelsAndVersion() throws {
    let modelNames = Set(EnoughSchemaV1.models.map { String(describing: $0) })
    XCTAssertEqual(
      modelNames,
      ["TripProfileRecord", "EntitlementRecord", "CardSRSRecord", "DailyActivityRecord"]
    )
    XCTAssertEqual(EnoughSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))

    let schema = Schema(versionedSchema: EnoughSchemaV1.self)
    let configuration = ModelConfiguration(
      UUID().uuidString,
      schema: schema,
      isStoredInMemoryOnly: true
    )
    XCTAssertNoThrow(
      try ModelContainer(
        for: schema, migrationPlan: EnoughMigrationPlan.self, configurations: [configuration])
    )
  }

  func testTripProfileRecordRoundTrips() throws {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    let record = TripProfileRecord(
      countryId: "japan",
      duration: "week",
      scenarioIds: ["greetings", "eating-out"],
      startDate: startDate,
      accentRawValue: "japan",
      isActive: true
    )
    context.insert(record)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<TripProfileRecord>())
    XCTAssertEqual(fetched.count, 1)
    let fetchedRecord = try XCTUnwrap(fetched.first)
    XCTAssertEqual(fetchedRecord.countryId, "japan")
    XCTAssertEqual(fetchedRecord.duration, "week")
    XCTAssertEqual(fetchedRecord.scenarioIds, ["greetings", "eating-out"])
    XCTAssertEqual(fetchedRecord.startDate, startDate)
    XCTAssertEqual(fetchedRecord.accentRawValue, "japan")
    XCTAssertEqual(fetchedRecord.isActive, true)
  }

  func testEntitlementRecordRoundTrips() throws {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    let grantedAt = Date(timeIntervalSince1970: 1_700_000_100)

    let record = EntitlementRecord(
      productId: "japan-eating-out", kind: "deck", grantedAt: grantedAt)
    context.insert(record)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<EntitlementRecord>())
    XCTAssertEqual(fetched.count, 1)
    let fetchedRecord = try XCTUnwrap(fetched.first)
    XCTAssertEqual(fetchedRecord.productId, "japan-eating-out")
    XCTAssertEqual(fetchedRecord.kind, "deck")
    XCTAssertEqual(fetchedRecord.grantedAt, grantedAt)
  }

  func testCardSRSRecordRoundTripsWithNilOptionalFields() throws {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)

    let record = CardSRSRecord(
      deckId: "japan-greetings",
      cardId: "card-1",
      statusRaw: "new",
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
      lapses: 0,
      dueAt: nil,
      lastReviewedAt: nil
    )
    context.insert(record)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<CardSRSRecord>())
    XCTAssertEqual(fetched.count, 1)
    let fetchedRecord = try XCTUnwrap(fetched.first)
    XCTAssertEqual(fetchedRecord.deckId, "japan-greetings")
    XCTAssertEqual(fetchedRecord.cardId, "card-1")
    XCTAssertEqual(fetchedRecord.statusRaw, "new")
    XCTAssertEqual(fetchedRecord.easeFactor, 2.5)
    XCTAssertEqual(fetchedRecord.intervalDays, 0)
    XCTAssertEqual(fetchedRecord.repetitions, 0)
    XCTAssertEqual(fetchedRecord.lapses, 0)
    XCTAssertNil(fetchedRecord.dueAt)
    XCTAssertNil(fetchedRecord.lastReviewedAt)
  }

  func testDailyActivityRecordRoundTrips() throws {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    let day = Date(timeIntervalSince1970: 1_700_000_200)

    let record = DailyActivityRecord(
      day: day, cardsReviewed: 5, cardsLearned: 2, secondsStudied: 300)
    context.insert(record)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<DailyActivityRecord>())
    XCTAssertEqual(fetched.count, 1)
    let fetchedRecord = try XCTUnwrap(fetched.first)
    XCTAssertEqual(fetchedRecord.day, day)
    XCTAssertEqual(fetchedRecord.cardsReviewed, 5)
    XCTAssertEqual(fetchedRecord.cardsLearned, 2)
    XCTAssertEqual(fetchedRecord.secondsStudied, 300)
  }

  func testTwoInMemoryContainersAreIsolated() throws {
    let containerA = try PersistenceStack.container(inMemory: true)
    let containerB = try PersistenceStack.container(inMemory: true)

    let contextA = ModelContext(containerA)
    let record = EntitlementRecord(
      productId: "isolated-deck", kind: "deck", grantedAt: Date(timeIntervalSince1970: 0))
    contextA.insert(record)
    try contextA.save()

    let contextB = ModelContext(containerB)
    let fetchedFromB = try contextB.fetch(FetchDescriptor<EntitlementRecord>())
    XCTAssertTrue(fetchedFromB.isEmpty)
  }
}
