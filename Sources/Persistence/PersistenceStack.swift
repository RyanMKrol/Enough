import Foundation
import SwiftData

enum PersistenceStack {
  static var models: [any PersistentModel.Type] { EnoughSchemaV1.models }

  static func container(inMemory: Bool = false) throws -> ModelContainer {
    let schema = Schema(versionedSchema: EnoughSchemaV1.self)
    let configuration = ModelConfiguration(
      inMemory ? UUID().uuidString : "Enough",
      schema: schema,
      isStoredInMemoryOnly: inMemory
    )
    return try ModelContainer(
      for: schema,
      migrationPlan: EnoughMigrationPlan.self,
      configurations: [configuration]
    )
  }
}
