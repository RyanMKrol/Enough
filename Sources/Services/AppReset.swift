import Foundation
import SwiftData

enum AppReset {
  /// Deletes ALL rows of all four SwiftData record types (TripProfileRecord,
  /// EntitlementRecord, CardSRSRecord, DailyActivityRecord), saves the context, and
  /// removes the "debug.dayOffset" key from the given UserDefaults.
  static func wipeAll(context: ModelContext, userDefaults: UserDefaults = .standard) throws {
    try context.delete(model: TripProfileRecord.self)
    try context.delete(model: EntitlementRecord.self)
    try context.delete(model: CardSRSRecord.self)
    try context.delete(model: DailyActivityRecord.self)
    try context.save()
    userDefaults.removeObject(forKey: AdjustableDateProvider.offsetKey)
  }
}
