import SwiftData
import XCTest

@testable import Enough

@MainActor
class DebugSRSToolsTests: XCTestCase {
  private func makeStore() throws -> (CardSRSStore, ModelContext) {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    return (CardSRSStore(context: context), context)
  }

  func testForceAllDueUpdatesNonNewCardsAndReturnsCount() throws {
    let (store, context) = try makeStore()
    let now = Date()
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    let sixDaysOut = Calendar.current.date(byAdding: .day, value: 6, to: now)!

    let deckId = "test-deck"
    let newRecord = try store.upsert(
      deckId: deckId, cardId: "new-card", statusRaw: "new", easeFactor: 2.5,
      intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil, lastReviewedAt: nil)
    let learningRecord = try store.upsert(
      deckId: deckId, cardId: "learning-card", statusRaw: "learning", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: tomorrow, lastReviewedAt: nil)
    let reviewRecord = try store.upsert(
      deckId: deckId, cardId: "review-card", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 6, repetitions: 3, lapses: 0, dueAt: sixDaysOut, lastReviewedAt: nil)

    let count = try DebugSRSTools.forceAllDue(store: store, now: now)

    XCTAssertEqual(count, 2, "Should return count of non-new records updated")

    let updatedNew = try store.record(deckId: deckId, cardId: "new-card")
    let updatedLearning = try store.record(deckId: deckId, cardId: "learning-card")
    let updatedReview = try store.record(deckId: deckId, cardId: "review-card")

    XCTAssertNil(updatedNew?.dueAt, "New card should keep nil dueAt")
    XCTAssertEqual(updatedLearning?.dueAt, now, "Learning card should have dueAt = now")
    XCTAssertEqual(updatedReview?.dueAt, now, "Review card should have dueAt = now")
  }

  func testDueRecordsAfterForceAllDueIncludesUpdatedCards() throws {
    let (store, context) = try makeStore()
    let now = Date()
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    let sixDaysOut = Calendar.current.date(byAdding: .day, value: 6, to: now)!

    let deckId = "test-deck"
    let deckIds: Set<String> = [deckId]

    _ = try store.upsert(
      deckId: deckId, cardId: "new-card", statusRaw: "new", easeFactor: 2.5,
      intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil, lastReviewedAt: nil)
    _ = try store.upsert(
      deckId: deckId, cardId: "learning-card", statusRaw: "learning", easeFactor: 2.5,
      intervalDays: 1, repetitions: 1, lapses: 0, dueAt: tomorrow, lastReviewedAt: nil)
    _ = try store.upsert(
      deckId: deckId, cardId: "review-card", statusRaw: "review", easeFactor: 2.5,
      intervalDays: 6, repetitions: 3, lapses: 0, dueAt: sixDaysOut, lastReviewedAt: nil)

    try DebugSRSTools.forceAllDue(store: store, now: now)

    let dueRecords = try store.dueRecords(now: now, ownedDeckIds: deckIds)

    XCTAssertEqual(dueRecords.count, 2, "Should return exactly 2 due records (learning + review)")
    let cardIds = Set(dueRecords.map(\.cardId))
    XCTAssertEqual(cardIds, ["learning-card", "review-card"])
  }
}
