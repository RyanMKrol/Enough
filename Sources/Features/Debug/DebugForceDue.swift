import Foundation

enum DebugForceDue {
  static let section = DebugSection(
    id: "srs",
    title: "Spaced repetition",
    rows: [
      DebugRow(
        id: "force-due",
        title: "Make everything due now",
        subtitle: "Every studied card becomes reviewable immediately",
        kind: .action { @MainActor services in
          let count = try DebugSRSTools.forceAllDue(
            store: services.cardSRSStore, now: services.dateProvider.now)
          return "\(count) cards due"
        }
      )
    ]
  )
}
