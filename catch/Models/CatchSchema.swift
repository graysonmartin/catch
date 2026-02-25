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

enum CatchSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Cat.self, Encounter.self, CareEntry.self, UserProfile.self]
    }
}

enum CatchSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Cat.self, Encounter.self, CareEntry.self, UserProfile.self]
    }
}

enum CatchMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CatchSchemaV1.self, CatchSchemaV2.self, CatchSchemaV3.self, CatchSchemaV4.self]
    }
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
    }

    private static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: CatchSchemaV1.self,
        toVersion: CatchSchemaV2.self
    )

    private static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: CatchSchemaV2.self,
        toVersion: CatchSchemaV3.self
    )

    private static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: CatchSchemaV3.self,
        toVersion: CatchSchemaV4.self
    )
}
