import Foundation

enum DebugSRSTools {
  static func forceAllDue(store: CardSRSStore, now: Date) throws -> Int {
    try store.forceAllDue(now: now)
  }
}
