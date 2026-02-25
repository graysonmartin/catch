import SwiftData

enum CatchSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Cat.self, Encounter.self, CareEntry.self, UserProfile.self]
    }
}

enum CatchSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Cat.self, Encounter.self, CareEntry.self, UserProfile.self]
    }
}

enum CatchMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CatchSchemaV1.self, CatchSchemaV2.self]
    }
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    private static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: CatchSchemaV1.self,
        toVersion: CatchSchemaV2.self
    )
}
