import XCTest
import SwiftData

@MainActor
final class CatchSchemaTests: XCTestCase {

    // MARK: - V1

    func test_v1VersionIdentifier_is1_0_0() {
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

    // MARK: - Migration Plan

    func test_migrationPlanIncludesSingleSchema() {
        let schemas = CatchMigrationPlan.schemas
        XCTAssertEqual(schemas.count, 1)
        XCTAssertTrue(schemas[0] == CatchSchemaV1.self)
    }

    func test_migrationPlanHasNoStages() {
        XCTAssertEqual(CatchMigrationPlan.stages.count, 0)
    }

    func test_v1ModelContainerCanBeCreated() throws {
        let schema = Schema(versionedSchema: CatchSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 4)
    }
}
