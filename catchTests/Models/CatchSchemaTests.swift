import Testing
import SwiftData

@Suite("CatchSchema")
struct CatchSchemaTests {

    @Test("V1 version identifier is 1.0.0")
    func versionIdentifier() {
        let version = CatchSchemaV1.versionIdentifier
        #expect(version == Schema.Version(1, 0, 0))
    }

    @Test("V1 declares all four model types")
    func modelsContainAllTypes() {
        let models = CatchSchemaV1.models
        #expect(models.count == 4)
        #expect(models.contains(where: { $0 == Cat.self }))
        #expect(models.contains(where: { $0 == Encounter.self }))
        #expect(models.contains(where: { $0 == CareEntry.self }))
        #expect(models.contains(where: { $0 == UserProfile.self }))
    }

    @Test("Migration plan includes V1 schema")
    func migrationPlanSchemas() {
        let schemas = CatchMigrationPlan.schemas
        #expect(schemas.count == 1)
        #expect(schemas.first == CatchSchemaV1.self)
    }

    @Test("Migration plan has no stages yet")
    func migrationPlanStagesEmpty() {
        #expect(CatchMigrationPlan.stages.isEmpty)
    }

    @Test("ModelContainer can be created with migration plan")
    @MainActor
    func modelContainerWithMigrationPlan() throws {
        let schema = Schema(versionedSchema: CatchSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CatchMigrationPlan.self,
            configurations: config
        )
        #expect(container.schema.entities.count == 4)
    }
}
