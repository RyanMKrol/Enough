import SwiftData
import XCTest

@testable import Enough

@MainActor
class CardSRSStoreTests: XCTestCase {
  private func makeStore() throws -> (CardSRSStore, ModelContext) {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    return (CardSRSStore(context: context), context)
  }

  func testRecordIsNilForUntrackedPair() throws {
    let (store, _) = try makeStore()
    XCTAssertNil(try store.record(deckId: "A", cardId: "card-1"))
  }

  func testUpsertInsertsNewRecord() throws {
    let (store, _) = try makeStore()
    let dueAt = Date(timeIntervalSince1970: 1_700_000_000)
    let lastReviewedAt = Date(timeIntervalSince1970: 1_699_000_000)

    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.3,
      intervalDays: 4, repetitions: 2, lapses: 1, dueAt: dueAt, lastReviewedAt: lastReviewedAt
    )

    let record = try XCTUnwrap(try store.record(deckId: "A", cardId: "card-1"))
    XCTAssertEqual(record.deckId, "A")
    XCTAssertEqual(record.cardId, "card-1")
    XCTAssertEqual(record.statusRaw, "review")
    XCTAssertEqual(record.easeFactor, 2.3)
    XCTAssertEqual(record.intervalDays, 4)
    XCTAssertEqual(record.repetitions, 2)
    XCTAssertEqual(record.lapses, 1)
    XCTAssertEqual(record.dueAt, dueAt)
    XCTAssertEqual(record.lastReviewedAt, lastReviewedAt)
  }

  func testUpsertOnSamePairMutatesExistingRow() throws {
    let (store, context) = try makeStore()
    let firstDueAt = Date(timeIntervalSince1970: 1_700_000_000)
    let secondDueAt = Date(timeIntervalSince1970: 1_701_000_000)

    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.3,
      intervalDays: 4, repetitions: 2, lapses: 1, dueAt: firstDueAt, lastReviewedAt: nil
    )
    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.6,
      intervalDays: 8, repetitions: 3, lapses: 1, dueAt: secondDueAt, lastReviewedAt: secondDueAt
    )

    let record = try XCTUnwrap(try store.record(deckId: "A", cardId: "card-1"))
    XCTAssertEqual(record.easeFactor, 2.6)
    XCTAssertEqual(record.intervalDays, 8)
    XCTAssertEqual(record.repetitions, 3)
    XCTAssertEqual(record.dueAt, secondDueAt)
    XCTAssertEqual(record.lastReviewedAt, secondDueAt)

    let allRecords = try context.fetch(FetchDescriptor<CardSRSRecord>())
    XCTAssertEqual(allRecords.count, 1)
  }

  func testRecordsForDeckReturnsOnlyThatDecksRows() throws {
    let (store, _) = try makeStore()
    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    try store.upsert(
      deckId: "A", cardId: "card-2", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    try store.upsert(
      deckId: "B", cardId: "card-3", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )

    let deckARecords = try store.records(forDeck: "A")
    XCTAssertEqual(deckARecords.count, 2)
    XCTAssertEqual(Set(deckARecords.map(\.cardId)), ["card-1", "card-2"])
  }

  func testDueRecordsFiltersByStatusDuenessAndOwnedDecks() throws {
    let (store, _) = try makeStore()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let oneHour: TimeInterval = 3600

    // (a) review, due 1h ago, deck A
    try store.upsert(
      deckId: "A", cardId: "a", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: now.addingTimeInterval(-oneHour),
      lastReviewedAt: nil
    )
    // (b) review, due in 1h, deck A
    try store.upsert(
      deckId: "A", cardId: "b", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: now.addingTimeInterval(oneHour),
      lastReviewedAt: nil
    )
    // (c) new, no dueAt, deck A
    try store.upsert(
      deckId: "A", cardId: "c", statusRaw: "new", easeFactor: 2.5,
      intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    // (d) review, due 2h ago, deck B
    try store.upsert(
      deckId: "B", cardId: "d", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: now.addingTimeInterval(-2 * oneHour),
      lastReviewedAt: nil
    )

    let onlyA = try store.dueRecords(now: now, ownedDeckIds: ["A"])
    XCTAssertEqual(onlyA.map(\.cardId), ["a"])

    let aAndB = try store.dueRecords(now: now, ownedDeckIds: ["A", "B"])
    XCTAssertEqual(aAndB.map(\.cardId), ["d", "a"])
  }

  func testRecordsForDecksReturnsRowsAcrossMultipleDecks() throws {
    let (store, _) = try makeStore()
    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    try store.upsert(
      deckId: "B", cardId: "card-2", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    try store.upsert(
      deckId: "C", cardId: "card-3", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )

    let records = try store.records(forDecks: ["A", "B"])
    XCTAssertEqual(Set(records.map(\.cardId)), ["card-1", "card-2"])
  }

  func testUpsertBatchInsertsAndUpdatesInOneSave() throws {
    let (store, context) = try makeStore()
    let dueAt = Date(timeIntervalSince1970: 1_700_000_000)

    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.3,
      intervalDays: 4, repetitions: 2, lapses: 1, dueAt: nil, lastReviewedAt: nil
    )

    let updateCard1 = CardSRSStore.Update(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.6,
      intervalDays: 8, repetitions: 3, lapses: 1, dueAt: dueAt, lastReviewedAt: dueAt
    )
    let insertCard2 = CardSRSStore.Update(
      deckId: "A", cardId: "card-2", statusRaw: "new", easeFactor: 2.5,
      intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    try store.upsertBatch([updateCard1, insertCard2])

    let updated = try XCTUnwrap(try store.record(deckId: "A", cardId: "card-1"))
    XCTAssertEqual(updated.easeFactor, 2.6)
    XCTAssertEqual(updated.dueAt, dueAt)

    let inserted = try XCTUnwrap(try store.record(deckId: "A", cardId: "card-2"))
    XCTAssertEqual(inserted.statusRaw, "new")

    let allRecords = try context.fetch(FetchDescriptor<CardSRSRecord>())
    XCTAssertEqual(allRecords.count, 2)
  }

  func testUpsertBatchWithNoUpdatesIsNoOp() throws {
    let (store, _) = try makeStore()
    try store.upsertBatch([])
    XCTAssertTrue(try store.records(forDeck: "A").isEmpty)
  }

  func testResetDeletesAllRecords() throws {
    let (store, _) = try makeStore()
    try store.upsert(
      deckId: "A", cardId: "card-1", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )
    try store.upsert(
      deckId: "B", cardId: "card-2", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil, lastReviewedAt: nil
    )

    try store.reset()

    XCTAssertTrue(try store.records(forDeck: "A").isEmpty)
    XCTAssertTrue(try store.records(forDeck: "B").isEmpty)
  }
}
