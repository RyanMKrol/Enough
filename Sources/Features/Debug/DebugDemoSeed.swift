import Foundation
import SwiftData

enum DebugDemoSeed {
  static let section = DebugSection(
    id: "demo",
    title: "Demo",
    rows: [
      DebugRow(
        id: "seed-demo",
        title: "Seed demo state",
        subtitle: "Replaces ALL data with the design-mock fixture",
        kind: .action { @MainActor services in
          let context = ModelContext(services.container)
          try DemoSeeder.seed(
            content: services.contentStore, context: context, now: services.dateProvider.now)
          return "Demo state seeded — relaunch to see Home"
        }
      )
    ]
  )
}
