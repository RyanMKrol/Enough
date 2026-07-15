import XCTest

@testable import Enough

final class SRSEngineTests: XCTestCase {
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  func testGoodLadderFromNewCard() {
    var state = SRSState.newCard
    let expectedIntervals: [Double] = [1, 3, 8, 20]
    let expectedStatuses: [CardStatus] = [.learning, .learning, .review, .review]
    let expectedRepetitions = [1, 2, 3, 4]

    for i in 0..<4 {
      state = SRSEngine.apply(.good, to: state, now: now)
      XCTAssertEqual(state.intervalDays, expectedIntervals[i], "interval at step \(i)")
      XCTAssertEqual(state.status, expectedStatuses[i], "status at step \(i)")
      XCTAssertEqual(state.repetitions, expectedRepetitions[i], "repetitions at step \(i)")
      XCTAssertEqual(state.dueAt, now.addingTimeInterval(state.intervalDays * 86_400))
    }
    XCTAssertEqual(state.easeFactor, 2.5)
  }

  func testAgainOnReviewCard() {
    let state = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 8, repetitions: 3, lapses: 0, dueAt: nil)
    let next = SRSEngine.apply(.again, to: state, now: now)
    XCTAssertEqual(next.lapses, 1)
    XCTAssertEqual(next.repetitions, 0)
    XCTAssertEqual(next.status, .learning)
    XCTAssertEqual(next.intervalDays, 1.0 / 1440.0)
    XCTAssertEqual(next.easeFactor, 2.3, accuracy: 0.0001)
  }

  func testAgainOnLearningCardDoesNotIncrementLapses() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil)
    let next = SRSEngine.apply(.again, to: state, now: now)
    XCTAssertEqual(next.lapses, 0)
  }

  func testHardOnLearningCardSubDayInterval() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1.0 / 1440.0, repetitions: 1, lapses: 0,
      dueAt: nil)
    let next = SRSEngine.apply(.hard, to: state, now: now)
    XCTAssertEqual(next.intervalDays, 1.0)
    XCTAssertEqual(next.easeFactor, 2.35, accuracy: 0.0001)
  }

  func testHardOnLearningCardAtOneDayHolds() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil)
    let next = SRSEngine.apply(.hard, to: state, now: now)
    XCTAssertEqual(next.intervalDays, 1.0)
    XCTAssertEqual(next.easeFactor, 2.35, accuracy: 0.0001)
  }

  func testHardOnReviewCard() {
    let state = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 8, repetitions: 3, lapses: 0, dueAt: nil)
    let next = SRSEngine.apply(.hard, to: state, now: now)
    XCTAssertEqual(next.intervalDays, 10)
  }

  func testEasyOnLearningCardAtOneDay() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: nil)
    let next = SRSEngine.apply(.easy, to: state, now: now)
    XCTAssertEqual(next.status, .review)
    XCTAssertEqual(next.intervalDays, 6)
    XCTAssertEqual(next.easeFactor, 2.65, accuracy: 0.0001)
  }

  func testEaseFloor() {
    var state = SRSState.newCard
    for _ in 0..<10 {
      state = SRSEngine.apply(.again, to: state, now: now)
    }
    XCTAssertEqual(state.easeFactor, 1.3, accuracy: 0.0001)
  }
}
