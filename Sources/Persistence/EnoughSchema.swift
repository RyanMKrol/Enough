import Foundation
import SwiftData

enum EnoughSchemaV1: VersionedSchema {
  static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
  static var models: [any PersistentModel.Type] {
    [TripProfileRecord.self, EntitlementRecord.self, CardSRSRecord.self, DailyActivityRecord.self]
  }
}

enum EnoughMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [EnoughSchemaV1.self] }
  static var stages: [MigrationStage] { [] }
}
