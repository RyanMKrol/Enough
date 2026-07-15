import Foundation

/// System time shifted by a persisted whole-day offset (debug "time travel").
final class AdjustableDateProvider: DateProvider {
  static let offsetKey = "debug.dayOffset"

  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  var dayOffset: Int {
    get {
      userDefaults.integer(forKey: Self.offsetKey)
    }
    set {
      userDefaults.set(newValue, forKey: Self.offsetKey)
    }
  }

  var now: Date {
    Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
  }
}
