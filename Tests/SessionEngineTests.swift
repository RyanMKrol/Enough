import XCTest

@testable import Enough

final class SessionEngineTests: XCTestCase {
  private func newState() -> SRSState {
    SRSState(status: .new, easeFactor: 2.5, intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil)
  }

  private func cards() -> [SessionCard] {
    ["A", "B", "C"].map { SessionCard(deckId: "d1", cardId: $0, state: newState()) }
  }

  func testLearnWithOneMiss() {
    var fake = Date(timeIntervalSince1970: 1_800_000_000)
    let engine = SessionEngine(mode: .learn, cards: cards(), now: { fake })

    XCTAssertEqual(engine.current?.cardId, "A")
    XCTAssertEqual(engine.submitMultipleChoice(correct: true), .good)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "B")
    XCTAssertEqual(engine.submitMultipleChoice(correct: false), .again)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "C")
    XCTAssertEqual(engine.submitMultipleChoice(correct: true), .good)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "B")
    XCTAssertFalse(engine.isComplete)
    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    engine.advance()

    XCTAssertTrue(engine.isComplete)
    let progress = engine.progress
    XCTAssertEqual(progress.done, 3)
    XCTAssertEqual(progress.total, 3)

    let graded = engine.gradedResults
    XCTAssertEqual(graded.map(\.card.cardId), ["A", "B", "C"])
    XCTAssertEqual(graded.map(\.grade), [.good, .again, .good])

    XCTAssertEqual(engine.summary().correctCount, 2)
    fake = fake.addingTimeInterval(10)
  }

  func testRequeueClamp() {
    let fake = Date(timeIntervalSince1970: 1_800_000_000)
    let engine = SessionEngine(mode: .learn, cards: cards(), now: { fake })

    XCTAssertEqual(engine.submitMultipleChoice(correct: true), .good)
    engine.advance()
    XCTAssertEqual(engine.submitMultipleChoice(correct: true), .good)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "C")
    XCTAssertEqual(engine.submitMultipleChoice(correct: false), .again)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "C")
    XCTAssertFalse(engine.isComplete)
    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    engine.advance()

    XCTAssertTrue(engine.isComplete)
  }

  func testReview() {
    let fake = Date(timeIntervalSince1970: 1_800_000_000)
    let engine = SessionEngine(mode: .review, cards: cards(), now: { fake })

    XCTAssertEqual(engine.current?.cardId, "A")
    engine.submitGrade(.easy)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "B")
    engine.submitGrade(.again)
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "C")
    engine.submitGrade(.good)
    engine.advance()

    XCTAssertTrue(engine.isComplete)

    let graded = engine.gradedResults
    XCTAssertEqual(graded.map(\.card.cardId), ["A", "B", "C"])
    XCTAssertEqual(graded.map(\.grade), [.easy, .again, .good])
    XCTAssertEqual(engine.summary().correctCount, 2)

    // submitMultipleChoice should be a no-op in review mode.
    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    XCTAssertTrue(engine.isComplete)
  }

  func testPractice() {
    let fake = Date(timeIntervalSince1970: 1_800_000_000)
    let engine = SessionEngine(mode: .practice, cards: cards(), now: { fake })

    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "B")
    XCTAssertNil(engine.submitMultipleChoice(correct: false))
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "C")
    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    engine.advance()

    XCTAssertEqual(engine.current?.cardId, "B")
    XCTAssertFalse(engine.isComplete)
    XCTAssertNil(engine.submitMultipleChoice(correct: true))
    engine.advance()

    XCTAssertTrue(engine.isComplete)
    XCTAssertTrue(engine.gradedResults.isEmpty)
    XCTAssertEqual(engine.summary().mode, .practice)
    XCTAssertEqual(engine.summary().cardsCompleted, 3)
  }

  func testDuration() {
    var fake = Date(timeIntervalSince1970: 1_800_000_000)
    let engine = SessionEngine(mode: .practice, cards: cards(), now: { fake })
    fake = fake.addingTimeInterval(250)
    XCTAssertEqual(engine.summary().duration, 250)
  }
}
