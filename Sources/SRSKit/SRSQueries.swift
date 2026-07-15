import Foundation

nonisolated extension SRSEngine {
  static func previewInterval(_ grade: SRSGrade, for state: SRSState) -> TimeInterval {
    let fixedDate = Date(timeIntervalSince1970: 0)
    let nextState = apply(grade, to: state, now: fixedDate)
    return nextState.intervalDays * 86_400
  }

  static func previewLabel(_ grade: SRSGrade, for state: SRSState) -> String {
    let interval = previewInterval(grade, for: state)
    let oneHour = 3600.0
    let oneDay = 86_400.0

    if interval < oneHour {
      return "<1 min"
    }

    if interval < oneDay {
      return "<1 day"
    }

    let days = Int((interval / oneDay).rounded())

    if days == 1 {
      return "1 day"
    }

    if days < 30 {
      return "\(days) days"
    }

    let months = Int((Double(days) / 30.0).rounded())
    if months == 1 {
      return "1 month"
    }

    return "\(months) months"
  }

  static func isDue(_ state: SRSState, now: Date) -> Bool {
    guard let dueAt = state.dueAt else { return false }
    return dueAt <= now
  }

  // swiftlint:disable:next inclusive_language
  static func isMastered(_ state: SRSState) -> Bool {
    return state.status == .review && state.intervalDays >= 21
  }

  static func nextDueLabel(_ dueAt: Date, now: Date, calendar: Calendar = .current) -> String {
    if dueAt <= now {
      return "now"
    }

    let secondsUntilDue = dueAt.timeIntervalSince(now)
    let oneHour = 3600.0
    let oneDay = 86_400.0

    if secondsUntilDue < oneHour {
      let minutes = max(1, Int(secondsUntilDue / 60))
      if minutes == 1 {
        return "in 1 minute"
      }
      return "in \(minutes) minutes"
    }

    let dueAtStartOfDay = calendar.startOfDay(for: dueAt)
    let nowStartOfDay = calendar.startOfDay(for: now)
    let components = calendar.dateComponents([.day], from: nowStartOfDay, to: dueAtStartOfDay)
    let daysDifference = components.day ?? 0

    if secondsUntilDue < oneDay && daysDifference == 0 {
      let hours = max(1, Int(secondsUntilDue / 3600))
      if hours == 1 {
        return "in 1 hour"
      }
      return "in \(hours) hours"
    }

    if daysDifference == 1 {
      return "tomorrow"
    }

    return "in \(daysDifference) days"
  }
}
