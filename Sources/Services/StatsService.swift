import Foundation

enum DayDot: String, Equatable {
  case done
  case today
  case missed
  case upcoming
}

final class StatsService {
  private let activityStore: ActivityStore
  private let dateProvider: DateProvider
  private let calendar: Calendar

  init(activityStore: ActivityStore, dateProvider: DateProvider, calendar: Calendar = .current) {
    self.activityStore = activityStore
    self.dateProvider = dateProvider
    self.calendar = calendar
  }

  func currentStreak() throws -> Int {
    let now = dateProvider.now
    let todayStart = calendar.startOfDay(for: now)

    // Check if today has activity
    if hasActivity(on: todayStart) {
      return try countConsecutiveDaysWithActivity(from: todayStart, goingBackward: true)
    }

    // Check if yesterday has activity (streak survives with yesterday anchor)
    let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
    if hasActivity(on: yesterdayStart) {
      return try countConsecutiveDaysWithActivity(from: yesterdayStart, goingBackward: true)
    }

    // Neither today nor yesterday has activity
    return 0
  }

  func weekDots() throws -> [DayDot] {
    let now = dateProvider.now

    // Create a calendar with firstWeekday = 2 (Monday) to force Monday start
    var mondayCalendar = calendar
    mondayCalendar.firstWeekday = 2

    // Get the week interval containing now
    guard let weekInterval = mondayCalendar.dateInterval(of: .weekOfYear, for: now) else {
      return Array(repeating: .upcoming, count: 7)
    }

    let mondayOfWeek = weekInterval.start
    let todayStart = calendar.startOfDay(for: now)

    var dots: [DayDot] = []

    for dayOffset in 0..<7 {
      guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: mondayOfWeek) else {
        dots.append(.upcoming)
        continue
      }

      let dayStart = calendar.startOfDay(for: dayDate)

      // First match wins: activity → .done; is today (no activity) → .today; before today → .missed; after today → .upcoming
      if hasActivity(on: dayStart) {
        dots.append(.done)
      } else if dayStart == todayStart {
        dots.append(.today)
      } else if dayStart < todayStart {
        dots.append(.missed)
      } else {
        dots.append(.upcoming)
      }
    }

    return dots
  }

  func totalMinutes() throws -> Int {
    let allRecords = try activityStore.all()
    let totalSeconds = allRecords.reduce(0) { $0 + $1.secondsStudied }
    return Int((Double(totalSeconds) / 60.0).rounded())
  }

  // MARK: - Private helpers

  private func hasActivity(on day: Date) -> Bool {
    guard let record = try? activityStore.record(for: day) else {
      return false
    }
    return (record.cardsReviewed + record.cardsLearned > 0) || record.secondsStudied > 0
  }

  private func countConsecutiveDaysWithActivity(
    from startDay: Date, goingBackward: Bool
  ) throws -> Int {
    var count = 0
    var currentDay = startDay

    while hasActivity(on: currentDay) {
      count += 1
      if goingBackward {
        guard let prevDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
          break
        }
        currentDay = prevDay
      } else {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
          break
        }
        currentDay = nextDay
      }
    }

    return count
  }
}
