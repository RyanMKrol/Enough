import XCTest
@testable import Enough

final class SRSQueueBuilderTests: XCTestCase {
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  private func entry(id: String, dueAt: Date?) -> QueueEntry {
    QueueEntry(
      cardId: id, deckId: "deck1",
      state: SRSState(
        status: .review, easeFactor: 2.5, intervalDays: 5, repetitions: 2, lapses: 0,
        dueAt: dueAt))
  }

  private var fixtures: [QueueEntry] {
    let future = entry(id: "future", dueAt: now.addingTimeInterval(3_600))
    let twoHoursAgo = entry(id: "twoHoursAgo", dueAt: now.addingTimeInterval(-7_200))
    let newCard = entry(id: "new", dueAt: nil)
    let oneHourAgo = entry(id: "oneHourAgo", dueAt: now.addingTimeInterval(-3_600))
    let exactlyNow = entry(id: "exactlyNow", dueAt: now)
    return [future, twoHoursAgo, newCard, oneHourAgo, exactlyNow]
  }

  func testReviewQueueOrdersMostOverdueFirstAndExcludesFutureAndNew() {
    let result = SRSQueueBuilder.reviewQueue(from: fixtures, now: now)
    XCTAssertEqual(result.map(\.cardId), ["twoHoursAgo", "oneHourAgo", "exactlyNow"])
  }

  func testReviewQueueLimit() {
    let limited = SRSQueueBuilder.reviewQueue(from: fixtures, now: now, limit: 2)
    XCTAssertEqual(limited.map(\.cardId), ["twoHoursAgo", "oneHourAgo"])

    let unlimited = SRSQueueBuilder.reviewQueue(from: fixtures, now: now, limit: nil)
    XCTAssertEqual(unlimited.map(\.cardId), ["twoHoursAgo", "oneHourAgo", "exactlyNow"])
  }

  func testLearnBatchTakesFirstNInInputOrder() {
    let twenty = (1...20).map { "card\($0)" }
    XCTAssertEqual(SRSQueueBuilder.learnBatch(newCardIds: twenty), Array(twenty.prefix(12)))

    let five = (1...5).map { "card\($0)" }
    XCTAssertEqual(SRSQueueBuilder.learnBatch(newCardIds: five), five)

    XCTAssertEqual(SRSQueueBuilder.learnBatch(newCardIds: twenty, size: 5), Array(twenty.prefix(5)))
  }

  func testRequeuePositionPinned() {
    XCTAssertEqual(SRSQueueBuilder.requeuePosition(queueLength: 0), 0)
    XCTAssertEqual(SRSQueueBuilder.requeuePosition(queueLength: 1), 1)
    XCTAssertEqual(SRSQueueBuilder.requeuePosition(queueLength: 2), 2)
    XCTAssertEqual(SRSQueueBuilder.requeuePosition(queueLength: 3), 3)
    XCTAssertEqual(SRSQueueBuilder.requeuePosition(queueLength: 10), 3)
  }
}
