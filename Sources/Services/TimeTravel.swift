import Foundation

enum TimeTravel {
  /// Current day offset, or nil when services.dateProvider is not an AdjustableDateProvider.
  static func offset(in services: AppServices) -> Int? {
    guard let provider = services.dateProvider as? AdjustableDateProvider else {
      return nil
    }
    return provider.dayOffset
  }

  /// Sets the day offset (no-op when the provider is not adjustable).
  static func setOffset(_ days: Int, in services: AppServices) {
    guard let provider = services.dateProvider as? AdjustableDateProvider else {
      return
    }
    provider.dayOffset = days
  }

  /// "today" for 0, "+3 days" / "-2 days" otherwise.
  static func label(for days: Int) -> String {
    switch days {
    case 0:
      return "today"
    case let n where n > 0:
      return "+\(n) day\(n == 1 ? "" : "s")"
    case let n where n < 0:
      return "\(n) day\(n == -1 ? "" : "s")"
    default:
      return "today"
    }
  }
}
