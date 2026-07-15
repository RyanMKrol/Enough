import SwiftData
import XCTest

@testable import Enough

@MainActor
class DeckProgressServiceTests: XCTestCase {
  private struct FixedDateProvider: DateProvider {
    let now: Date
  }

  private func makeContext() throws -> ModelContext {
    let container = try PersistenceStack.container(inMemory: true)
    return ModelContext(container)
  }

  private struct SeedSpec {
    let deckId: String
    let cardIds: [String]
    let statusRaw: String
    let intervalDays: Double
    let dueAt: Date?
  }

  private func seedRecords(_ store: CardSRSStore, _ spec: SeedSpec) throws {
    for cardId in spec.cardIds {
      try store.upsert(
        deckId: spec.deckId, cardId: cardId, statusRaw: spec.statusRaw, easeFactor: 2.5,
        intervalDays: spec.intervalDays, repetitions: 1, lapses: 0, dueAt: spec.dueAt,
        lastReviewedAt: nil
      )
    }
  }

  // MARK: - Bridge

  func testBridgeRoundTripsState() throws {
    let context = try makeContext()
    let record = CardSRSRecord(deckId: "A", cardId: "card-1", statusRaw: "new")
    context.insert(record)

    let dueAt = Date(timeIntervalSince1970: 1_700_000_000)
    let state = SRSState(
      status: .review, easeFactor: 2.1, intervalDays: 8, repetitions: 3, lapses: 1, dueAt: dueAt
    )
    let reviewedAt = Date(timeIntervalSince1970: 1_700_100_000)

    SRSBridge.apply(state, to: record, reviewedAt: reviewedAt)

    XCTAssertEqual(SRSBridge.state(from: record), state)
    XCTAssertEqual(record.lastReviewedAt, reviewedAt)
  }

  func testBridgeMapsUnknownStatusToNew() throws {
    let record = CardSRSRecord(deckId: "A", cardId: "card-1", statusRaw: "garbage")
    XCTAssertEqual(SRSBridge.state(from: record).status, .new)
  }

  // MARK: - DeckProgressService

  func testProgressForOwnedDeckWithMixedRecords() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    let cards = try content.cards(forDeck: "jp-greetings")
    XCTAssertGreaterThanOrEqual(cards.count, 10)
    let cardIds = cards.map(\.id)

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)

    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[0..<6]), statusRaw: "review",
        intervalDays: 30, dueAt: now.addingTimeInterval(oneHour)
      )
    )
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[6..<8]), statusRaw: "learning",
        intervalDays: 1, dueAt: now.addingTimeInterval(-oneHour)
      )
    )
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[8..<10]), statusRaw: "review",
        intervalDays: 8, dueAt: now.addingTimeInterval(-oneHour)
      )
    )

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let progress = try service.progress(forDeck: "jp-greetings")
    XCTAssertEqual(progress.total, 30)
    XCTAssertEqual(progress.learned, 10)
    XCTAssertEqual(progress.newCount, 20)
    XCTAssertEqual(progress.learning, 2)
    XCTAssertEqual(progress.mastered, 6)
    XCTAssertEqual(progress.dueNow, 4)
    XCTAssertEqual(progress.strength, 2)

    let totals = try service.totals()
    XCTAssertEqual(totals.due, 4)
    XCTAssertEqual(totals.learning, 2)
    XCTAssertEqual(totals.mastered, 6)

    XCTAssertEqual(try service.totalDue(), 4)
    XCTAssertEqual(try service.wordsLearned(), 10)
  }

  func testStrengthIsZeroWithNoRecords() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let progress = try service.progress(forDeck: "jp-greetings")
    XCTAssertEqual(progress.learned, 0)
    XCTAssertEqual(progress.strength, 0)
  }

  func testStrengthIsThreeWhenNoneDue() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)
    let cardIds = try content.cards(forDeck: "jp-greetings").map(\.id)

    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[0..<5]), statusRaw: "review",
        intervalDays: 30, dueAt: now.addingTimeInterval(oneHour)
      )
    )

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let progress = try service.progress(forDeck: "jp-greetings")
    XCTAssertEqual(progress.dueNow, 0)
    XCTAssertEqual(progress.strength, 3)
  }

  func testStrengthIsOneWhenDueExceedsHalfLearned() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)
    let cardIds = try content.cards(forDeck: "jp-greetings").map(\.id)

    // 4 learned total, 3 due -> 3*2 > 4
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[0..<3]), statusRaw: "review",
        intervalDays: 8, dueAt: now.addingTimeInterval(-oneHour)
      )
    )
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[3..<4]), statusRaw: "review",
        intervalDays: 30, dueAt: now.addingTimeInterval(oneHour)
      )
    )

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let progress = try service.progress(forDeck: "jp-greetings")
    XCTAssertEqual(progress.learned, 4)
    XCTAssertEqual(progress.dueNow, 3)
    XCTAssertEqual(progress.strength, 1)
  }

  func testStrengthIsTwoWhenDueIsPositiveButNotOverHalf() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)
    let cardIds = try content.cards(forDeck: "jp-greetings").map(\.id)

    // 10 learned, 2 due -> 2*2 <= 10
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[0..<2]), statusRaw: "review",
        intervalDays: 8, dueAt: now.addingTimeInterval(-oneHour)
      )
    )
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(cardIds[2..<10]), statusRaw: "review",
        intervalDays: 30, dueAt: now.addingTimeInterval(oneHour)
      )
    )

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let progress = try service.progress(forDeck: "jp-greetings")
    XCTAssertEqual(progress.learned, 10)
    XCTAssertEqual(progress.dueNow, 2)
    XCTAssertEqual(progress.strength, 2)
  }

  func testUnownedDeckDoesNotLeakIntoAggregates() throws {
    let context = try makeContext()
    let srsStore = CardSRSStore(context: context)
    let entitlements = EntitlementStore(context: context)
    let content = ContentStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    try entitlements.grant(productId: "jp-greetings", kind: "deck", now: now)
    let ownedCardIds = try content.cards(forDeck: "jp-greetings").map(\.id)

    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "jp-greetings", cardIds: Array(ownedCardIds[0..<2]), statusRaw: "review",
        intervalDays: 8, dueAt: now.addingTimeInterval(-oneHour)
      )
    )

    let service = DeckProgressService(
      content: content, srsStore: srsStore, entitlements: entitlements,
      dateProvider: FixedDateProvider(now: now)
    )

    let beforeTotals = try service.totals()
    let beforeDue = try service.totalDue()
    let beforeLearned = try service.wordsLearned()

    // Seed an unowned deck's records without granting entitlement for it.
    try seedRecords(
      srsStore,
      SeedSpec(
        deckId: "fr-greetings", cardIds: ["fr-1", "fr-2", "fr-3"], statusRaw: "review",
        intervalDays: 8, dueAt: now.addingTimeInterval(-oneHour)
      )
    )

    let afterTotals = try service.totals()
    XCTAssertEqual(afterTotals.due, beforeTotals.due)
    XCTAssertEqual(afterTotals.learning, beforeTotals.learning)
    XCTAssertEqual(afterTotals.mastered, beforeTotals.mastered)
    XCTAssertEqual(try service.totalDue(), beforeDue)
    XCTAssertEqual(try service.wordsLearned(), beforeLearned)
  }
}
