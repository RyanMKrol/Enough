import XCTest

@testable import Enough

final class SRSQueriesTests: XCTestCase {
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  var cal: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/London")!
    return calendar
  }

  func testPreviewLabelYoungCardQuartet() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: now)

    let againLabel = SRSEngine.previewLabel(.again, for: state)
    let hardLabel = SRSEngine.previewLabel(.hard, for: state)
    let goodLabel = SRSEngine.previewLabel(.good, for: state)
    let easyLabel = SRSEngine.previewLabel(.easy, for: state)

    XCTAssertEqual(againLabel, "<1 min")
    XCTAssertEqual(hardLabel, "1 day")
    XCTAssertEqual(goodLabel, "3 days")
    XCTAssertEqual(easyLabel, "6 days")
  }

  func testPreviewLabelNewCard() {
    let state = SRSState.newCard

    let goodLabel = SRSEngine.previewLabel(.good, for: state)
    let easyLabel = SRSEngine.previewLabel(.easy, for: state)

    XCTAssertEqual(goodLabel, "1 day")
    XCTAssertEqual(easyLabel, "6 days")
  }

  // swiftlint:disable:next inclusive_language
  func testMasteryBoundary() {
    // swiftlint:disable:next inclusive_language
    let notMasteredState = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 20.9, repetitions: 10, lapses: 0,
      dueAt: now)
    // swiftlint:disable:next inclusive_language
    let masteredState = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 21.0, repetitions: 10, lapses: 0,
      dueAt: now)

    XCTAssertFalse(SRSEngine.isMastered(notMasteredState))
    XCTAssertTrue(SRSEngine.isMastered(masteredState))
  }

  func testIsDueNilDueAt() {
    let state = SRSState(
      status: .new, easeFactor: 2.5, intervalDays: 0, repetitions: 0, lapses: 0, dueAt: nil)
    XCTAssertFalse(SRSEngine.isDue(state, now: now))
  }

  func testIsDueAtNow() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: now)
    XCTAssertTrue(SRSEngine.isDue(state, now: now))
  }

  func testIsDueFuture() {
    let futureDate = now.addingTimeInterval(60)
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0,
      dueAt: futureDate)
    XCTAssertFalse(SRSEngine.isDue(state, now: now))
  }

  func testNextDueLabelPast() {
    let pastDate = now.addingTimeInterval(-3600)
    let label = SRSEngine.nextDueLabel(pastDate, now: now, calendar: cal)
    XCTAssertEqual(label, "now")
  }

  func testNextDueLabelThirtyMinutes() {
    let futureDate = now.addingTimeInterval(30 * 60)
    let label = SRSEngine.nextDueLabel(futureDate, now: now, calendar: cal)
    XCTAssertEqual(label, "in 30 minutes")
  }

  func testNextDueLabelTwoHoursSameDay() {
    let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
    let twoHoursLater = morning.addingTimeInterval(2 * 3600)
    let label = SRSEngine.nextDueLabel(twoHoursLater, now: morning, calendar: cal)
    XCTAssertEqual(label, "in 2 hours")
  }

  func testNextDueLabelTomorrow() {
    let today = cal.startOfDay(for: now)
    let tomorrowStart = cal.date(byAdding: .day, value: 1, to: today)!
    let tomorrowNoon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrowStart)!
    let label = SRSEngine.nextDueLabel(tomorrowNoon, now: now, calendar: cal)
    XCTAssertEqual(label, "tomorrow")
  }

  func testNextDueLabelThreeDays() {
    let today = cal.startOfDay(for: now)
    let threeDaysLater = cal.date(byAdding: .day, value: 3, to: today)!
    let label = SRSEngine.nextDueLabel(threeDaysLater, now: now, calendar: cal)
    XCTAssertEqual(label, "in 3 days")
  }

  func testLabelFormattingFortyFiveDays() {
    let state = SRSState(
      status: .review, easeFactor: 2.5, intervalDays: 18, repetitions: 10, lapses: 0,
      dueAt: now)

    let label = SRSEngine.previewLabel(.good, for: state)
    XCTAssertEqual(label, "2 months")
  }

  func testPreviewIntervalReturnsSeconds() {
    let state = SRSState(
      status: .learning, easeFactor: 2.5, intervalDays: 1, repetitions: 1, lapses: 0, dueAt: now)

    let againInterval = SRSEngine.previewInterval(.again, for: state)
    let hardInterval = SRSEngine.previewInterval(.hard, for: state)

    XCTAssertEqual(againInterval, 60.0)
    XCTAssertEqual(hardInterval, 86_400.0)
  }

  func testNextDueLabelOneMinute() {
    let oneMinuteLater = now.addingTimeInterval(60)
    let label = SRSEngine.nextDueLabel(oneMinuteLater, now: now, calendar: cal)
    XCTAssertEqual(label, "in 1 minute")
  }

  func testNextDueLabelOneHour() {
    let oneHourLater = now.addingTimeInterval(3600)
    let morning = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
    let label = SRSEngine.nextDueLabel(
      morning.addingTimeInterval(3600), now: morning, calendar: cal)
    XCTAssertEqual(label, "in 1 hour")
  }
}
