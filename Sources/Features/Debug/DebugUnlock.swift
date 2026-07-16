import Foundation

enum DebugUnlock {
  static let section = DebugSection(
    id: "unlock",
    title: "Entitlements",
    rows: [
      DebugRow(
        id: "unlock-all",
        title: "Unlock everything",
        subtitle: "Grant every pack & bundle in the catalog",
        kind: .action { @MainActor services in
          let catalog = try services.contentStore.catalog()
          let count = try DebugEntitlementTools.grantAll(
            catalog: catalog,
            entitlements: services.entitlementStore,
            now: services.dateProvider.now
          )
          return "Unlocked \(count) packs"
        }
      )
    ]
  )
}
