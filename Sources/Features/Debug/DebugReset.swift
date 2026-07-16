import Foundation
import SwiftData

enum DebugReset {
  static let section = DebugSection(
    id: "reset",
    title: "Danger zone",
    rows: [
      DebugRow(
        id: "reset-all",
        title: "Reset all data",
        subtitle: "Wipes trip, purchases, SRS progress and history",
        kind: .action { @MainActor services in
          let context = ModelContext(services.container)
          try AppReset.wipeAll(context: context, userDefaults: .standard)
          return "Data wiped — relaunch the app"
        }
      )
    ]
  )
}
