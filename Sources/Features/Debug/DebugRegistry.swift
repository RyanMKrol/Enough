import Foundation

struct DebugSection: Identifiable {
  let id: String
  let title: String
  let rows: [DebugRow]
}

struct DebugRow: Identifiable {
  let id: String
  let title: String
  var subtitle: String?
  let kind: DebugRowKind
}

enum DebugRowKind {
  /// Runs work and returns a human-readable result message, shown as a toast.
  case action((AppServices) async throws -> String)
  /// Integer value with -/+ controls; `label` formats the current value for display.
  case stepper(get: (AppServices) -> Int, set: (AppServices, Int) -> Void, label: (Int) -> String)
  /// Read-only value, recomputed each render.
  case info((AppServices) -> String)
}

enum DebugProviders {
  /// Every debug task appends exactly one `Debug<Name>.section` literal to this array.
  static let all: [DebugSection] = [
    DebugAbout.section,
    DebugUnlock.section,
    DebugTimeTravel.section,
    DebugDemoSeed.section,
    DebugNotifications.section,
    DebugForceDue.section,
    DebugReset.section,  // swiftlint:disable:this trailing_comma
  ]
}
