import SwiftData
import XCTest

@testable import Enough

@MainActor
final class StatsServiceTests: XCTestCase {
  private var service: StatsService!
  private var store: ActivityStore!
  private var context: ModelContext!
  private var fixedDateProvider: FixedDateProvider!
  private var fixedCalendar: Calendar!

  override func setUp() {
    super.setUp()

    // Set up fixed calendar (Europe/London timezone)
    fixedCalendar = Calendar(identifier: .gregorian)
    fixedCalendar.timeZone = TimeZone(identifier: "Europe/London")!

    // Wednesday 2026-07-15 at 12:00 UTC
    var components = DateComponents()
    components.year = 2026
    components.month = 7
    components.day = 15
    components.hour = 12
    components.minute = 0
    components.second = 0
    let now = fixedCalendar.date(from: components)!

    fixedDateProvider = FixedDateProvider(now: now)

    // Set up in-memory store
    do {
      let container = try PersistenceStack.container(inMemory: true)
      context = ModelContext(container)
      store = ActivityStore(context: context)
      service = StatsService(
        activityStore: store, dateProvider: fixedDateProvider, calendar: fixedCalendar
      )
    } catch {
      XCTFail("Failed to set up: \(error)")
    }
  }

  // MARK: - currentStreak tests

  func testCurrentStreakWithActivityOnMonTueWedToday() throws {
    // Wednesday is today (2026-07-15)
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let tuesdayStart = fixedCalendar.date(byAdding: .day, value: -1, to: wednesdayStart)!
    let mondayStart = fixedCalendar.date(byAdding: .day, value: -2, to: wednesdayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: mondayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: tuesdayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: wednesdayStart)

    XCTAssertEqual(try service.currentStreak(), 3)
  }

  func testCurrentStreakWithActivityOnMonTueNoneToday() throws {
    // Monday and Tuesday have activity, Wednesday (today) does not
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let tuesdayStart = fixedCalendar.date(byAdding: .day, value: -1, to: wednesdayStart)!
    let mondayStart = fixedCalendar.date(byAdding: .day, value: -2, to: wednesdayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: mondayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: tuesdayStart)

    XCTAssertEqual(try service.currentStreak(), 2)
  }

  func testCurrentStreakWithActivityOnMonOnlyGapTueNoneToday() throws {
    // Only Monday has activity; gap on Tuesday; none today
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let mondayStart = fixedCalendar.date(byAdding: .day, value: -2, to: wednesdayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: mondayStart)

    XCTAssertEqual(try service.currentStreak(), 0)
  }

  func testCurrentStreakWithNoRows() throws {
    XCTAssertEqual(try service.currentStreak(), 0)
  }

  func testCurrentStreakWithAllZeroCountsDoesNotCountAsActivity() throws {
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let tuesdayStart = fixedCalendar.date(byAdding: .day, value: -1, to: wednesdayStart)!

    // Row with all zeros
    try store.addActivity(cardsReviewed: 0, cardsLearned: 0, seconds: 0, now: tuesdayStart)
    // Row with activity
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: wednesdayStart)

    XCTAssertEqual(try service.currentStreak(), 1)
  }

  // MARK: - weekDots tests

  func testWeekDotsWithActivityOnMonTueNoneWed() throws {
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let tuesdayStart = fixedCalendar.date(byAdding: .day, value: -1, to: wednesdayStart)!
    let mondayStart = fixedCalendar.date(byAdding: .day, value: -2, to: wednesdayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: mondayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: tuesdayStart)

    let dots = try service.weekDots()
    XCTAssertEqual(dots.count, 7)
    XCTAssertEqual(dots[0], .done)  // Monday
    XCTAssertEqual(dots[1], .done)  // Tuesday
    XCTAssertEqual(dots[2], .today)  // Wednesday (today, no activity)
    XCTAssertEqual(dots[3], .upcoming)  // Thursday
    XCTAssertEqual(dots[4], .upcoming)  // Friday
    XCTAssertEqual(dots[5], .upcoming)  // Saturday
    XCTAssertEqual(dots[6], .upcoming)  // Sunday
  }

  func testWeekDotsWithActivityAlsoOnWed() throws {
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let tuesdayStart = fixedCalendar.date(byAdding: .day, value: -1, to: wednesdayStart)!
    let mondayStart = fixedCalendar.date(byAdding: .day, value: -2, to: wednesdayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: mondayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: tuesdayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: wednesdayStart)

    let dots = try service.weekDots()
    XCTAssertEqual(dots[0], .done)  // Monday
    XCTAssertEqual(dots[1], .done)  // Tuesday
    XCTAssertEqual(dots[2], .done)  // Wednesday
    XCTAssertEqual(dots[3], .upcoming)  // Thursday
  }

  func testWeekDotsWithTueSkippedButMonAndWedDone() throws {
    let wednesdayStart = fixedCalendar.startOfDay(for: fixedDateProvider.now)
    let mondayStart = fixedCalendar.date(byAdding: .day, value: -2, to: wednesdayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: mondayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 60, now: wednesdayStart)

    let dots = try service.weekDots()
    XCTAssertEqual(dots[0], .done)  // Monday
    XCTAssertEqual(dots[1], .missed)  // Tuesday
    XCTAssertEqual(dots[2], .done)  // Wednesday
  }

  // MARK: - totalMinutes tests

  func testTotalMinutes90SecPlusPlus45Sec() throws {
    let twoDaysAgo = fixedCalendar.date(byAdding: .day, value: -2, to: fixedDateProvider.now)!
    let mondayStart = fixedCalendar.startOfDay(for: twoDaysAgo)
    let tuesdayStart = fixedCalendar.date(byAdding: .day, value: 1, to: mondayStart)!

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 90, now: mondayStart)
    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 45, now: tuesdayStart)

    // 135 seconds / 60 = 2.25 → rounds to 2
    XCTAssertEqual(try service.totalMinutes(), 2)
  }

  func testTotalMinutes150Sec() throws {
    let twoDaysAgo = fixedCalendar.date(byAdding: .day, value: -2, to: fixedDateProvider.now)!
    let mondayStart = fixedCalendar.startOfDay(for: twoDaysAgo)

    try store.addActivity(cardsReviewed: 1, cardsLearned: 0, seconds: 150, now: mondayStart)

    // 150 seconds / 60 = 2.5 → rounds to 3
    XCTAssertEqual(try service.totalMinutes(), 3)
  }
}

struct FixedDateProvider: DateProvider {
  let now: Date
}
