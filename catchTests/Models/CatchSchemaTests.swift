import XCTest
import SwiftData

@MainActor
final class CatchSchemaTests: XCTestCase {

    func test_versionIdentifier_is1_0_0() {
        let version = CatchSchemaV1.versionIdentifier
        XCTAssertEqual(version, Schema.Version(1, 0, 0))
    }

    func test_v1DeclaresAllFourModelTypes() {
        let models = CatchSchemaV1.models
        XCTAssertEqual(models.count, 4)
        XCTAssertTrue(models.contains(where: { $0 == Cat.self }))
        XCTAssertTrue(models.contains(where: { $0 == Encounter.self }))
        XCTAssertTrue(models.contains(where: { $0 == CareEntry.self }))
        XCTAssertTrue(models.contains(where: { $0 == UserProfile.self }))
    }

    func test_migrationPlanIncludesV1Schema() {
        let schemas = CatchMigrationPlan.schemas
        XCTAssertEqual(schemas.count, 1)
        XCTAssertTrue(schemas.first == CatchSchemaV1.self)
    }

    func test_migrationPlanHasNoStagesYet() {
        XCTAssertTrue(CatchMigrationPlan.stages.isEmpty)
    }

    func test_modelContainerCanBeCreatedWithMigrationPlan() throws {
        let schema = Schema(versionedSchema: CatchSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CatchMigrationPlan.self,
            configurations: config
        )
        XCTAssertEqual(container.schema.entities.count, 4)
    }
}
