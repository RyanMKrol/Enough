import SwiftData
import XCTest

@testable import Enough

@MainActor
class ActivityStoreTests: XCTestCase {
  private func makeStore() throws -> (ActivityStore, ModelContext) {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    return (ActivityStore(context: context), context)
  }

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components)!
  }

  func testRecordAndAllAreEmptyInitially() throws {
    let (store, _) = try makeStore()
    XCTAssertNil(try store.record(for: date(2026, 7, 1, 10, 0)))
    XCTAssertTrue(try store.all().isEmpty)
  }

  func testAddActivityCreatesRowWithNormalizedDay() throws {
    let (store, _) = try makeStore()
    let day1Morning = date(2026, 7, 1, 10, 0)

    try store.addActivity(cardsReviewed: 5, cardsLearned: 2, seconds: 60, now: day1Morning)

    let record = try XCTUnwrap(try store.record(for: day1Morning))
    XCTAssertEqual(record.cardsReviewed, 5)
    XCTAssertEqual(record.cardsLearned, 2)
    XCTAssertEqual(record.secondsStudied, 60)
    XCTAssertEqual(record.day, Calendar.current.startOfDay(for: day1Morning))
  }

  func testAddActivityAccumulatesOnSameDay() throws {
    let (store, _) = try makeStore()
    let day1Morning = date(2026, 7, 1, 10, 0)
    let day1Evening = date(2026, 7, 1, 22, 30)

    try store.addActivity(cardsReviewed: 5, cardsLearned: 2, seconds: 60, now: day1Morning)
    try store.addActivity(cardsReviewed: 3, cardsLearned: 0, seconds: 30, now: day1Evening)

    let all = try store.all()
    XCTAssertEqual(all.count, 1)
    XCTAssertEqual(all[0].cardsReviewed, 8)
    XCTAssertEqual(all[0].cardsLearned, 2)
    XCTAssertEqual(all[0].secondsStudied, 90)
  }

  func testAddActivityOnNextDayCreatesSecondRowInAscendingOrder() throws {
    let (store, _) = try makeStore()
    let day1 = date(2026, 7, 1, 10, 0)
    let day2 = date(2026, 7, 2, 10, 0)

    try store.addActivity(cardsReviewed: 5, cardsLearned: 2, seconds: 60, now: day1)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 1, seconds: 10, now: day2)

    let all = try store.all()
    XCTAssertEqual(all.count, 2)
    XCTAssertEqual(all[0].day, Calendar.current.startOfDay(for: day1))
    XCTAssertEqual(all[1].day, Calendar.current.startOfDay(for: day2))
  }

  func testRecordForFindsRowRegardlessOfTimeOfDay() throws {
    let (store, _) = try makeStore()
    let day1Morning = date(2026, 7, 1, 10, 0)
    let day1LateNight = date(2026, 7, 1, 23, 59)

    try store.addActivity(cardsReviewed: 5, cardsLearned: 2, seconds: 60, now: day1Morning)

    let record = try XCTUnwrap(try store.record(for: day1LateNight))
    XCTAssertEqual(record.cardsReviewed, 5)
  }

  func testResetDeletesAllRecords() throws {
    let (store, _) = try makeStore()
    let day1 = date(2026, 7, 1, 10, 0)
    let day2 = date(2026, 7, 2, 10, 0)
    try store.addActivity(cardsReviewed: 5, cardsLearned: 2, seconds: 60, now: day1)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 1, seconds: 10, now: day2)

    try store.reset()

    XCTAssertTrue(try store.all().isEmpty)
  }
}
