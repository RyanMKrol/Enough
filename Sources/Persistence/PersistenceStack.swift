import Foundation
import SwiftData

enum PersistenceStack {
  static var models: [any PersistentModel.Type] { EnoughSchemaV1.models }

  nonisolated static func storeURL(appGroupID: String? = nil) -> URL {
    if let appGroupID {
      guard
        let containerURL = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: appGroupID)
      else {
        fatalError(
          "Failed to access app group container for '\(appGroupID)'. "
            + "Ensure the entitlement is configured in your build settings.")
      }
      return containerURL.appendingPathComponent("Enough.store")
    }
    let applicationSupportURL = URL.applicationSupportDirectory
    let enoughDirectoryURL = applicationSupportURL.appendingPathComponent(
      "Enough", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: enoughDirectoryURL, withIntermediateDirectories: true)
    return enoughDirectoryURL.appendingPathComponent("Enough.store")
  }

  static func container(inMemory: Bool = false) throws -> ModelContainer {
    let schema = Schema(versionedSchema: EnoughSchemaV1.self)
    let configuration: ModelConfiguration
    if inMemory {
      configuration = ModelConfiguration(
        UUID().uuidString,
        schema: schema,
        isStoredInMemoryOnly: true
      )
    } else {
      let url = storeURL()
      configuration = ModelConfiguration(schema: schema, url: url)
    }
    return try ModelContainer(
      for: schema,
      migrationPlan: EnoughMigrationPlan.self,
      configurations: [configuration]
    )
  }

  static func container(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: EnoughSchemaV1.self)
    let configuration = ModelConfiguration(schema: schema, url: url)
    // Widget adoption: pass the app-group id here AND add a one-time file move from
    // the old URL if a store exists there — see the widget task when it lands.
    return try ModelContainer(
      for: schema,
      migrationPlan: EnoughMigrationPlan.self,
      configurations: [configuration]
    )
  }
}
