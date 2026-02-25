import XCTest
import SwiftData

@MainActor
final class CatchSchemaTests: XCTestCase {

    // MARK: - V1

    func test_v1VersionIdentifier_is1_0_0() {
        let version = CatchSchemaV1.versionIdentifier
        XCTAssertEqual(version, Schema.Version(1, 0, 0))
    }

    func test_v1DeclaresThreeModelTypes() {
        let models = CatchSchemaV1.models
        XCTAssertEqual(models.count, 3)
        XCTAssertTrue(models.contains(where: { $0 == Cat.self }))
        XCTAssertTrue(models.contains(where: { $0 == Encounter.self }))
        XCTAssertTrue(models.contains(where: { $0 == UserProfile.self }))
    }

    // MARK: - V2

    func test_v2VersionIdentifier_is2_0_0() {
        let version = CatchSchemaV2.versionIdentifier
        XCTAssertEqual(version, Schema.Version(2, 0, 0))
    }

    func test_v2DeclaresThreeModelTypes() {
        let models = CatchSchemaV2.models
        XCTAssertEqual(models.count, 3)
        XCTAssertTrue(models.contains(where: { $0 == Cat.self }))
        XCTAssertTrue(models.contains(where: { $0 == Encounter.self }))
        XCTAssertTrue(models.contains(where: { $0 == UserProfile.self }))
    }

    func test_v2ModelContainerCanBeCreated() throws {
        let schema = Schema(versionedSchema: CatchSchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 3)
    }

    // MARK: - V3

    func test_v3VersionIdentifier_is3_0_0() {
        let version = CatchSchemaV3.versionIdentifier
        XCTAssertEqual(version, Schema.Version(3, 0, 0))
    }

    func test_v3DeclaresThreeModelTypes() {
        let models = CatchSchemaV3.models
        XCTAssertEqual(models.count, 3)
        XCTAssertTrue(models.contains(where: { $0 == Cat.self }))
        XCTAssertTrue(models.contains(where: { $0 == Encounter.self }))
        XCTAssertTrue(models.contains(where: { $0 == UserProfile.self }))
    }

    func test_v3ModelContainerCanBeCreated() throws {
        let schema = Schema(versionedSchema: CatchSchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 3)
    }

    // MARK: - V4

    func test_v4VersionIdentifier_is4_0_0() {
        let version = CatchSchemaV4.versionIdentifier
        XCTAssertEqual(version, Schema.Version(4, 0, 0))
    }

    func test_v4DeclaresThreeModelTypes() {
        let models = CatchSchemaV4.models
        XCTAssertEqual(models.count, 3)
        XCTAssertTrue(models.contains(where: { $0 == Cat.self }))
        XCTAssertTrue(models.contains(where: { $0 == Encounter.self }))
        XCTAssertTrue(models.contains(where: { $0 == UserProfile.self }))
    }

    func test_v4ModelContainerCanBeCreated() throws {
        let schema = Schema(versionedSchema: CatchSchemaV4.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 3)
    }

    // MARK: - V5

    func test_v5VersionIdentifier_is5_0_0() {
        let version = CatchSchemaV5.versionIdentifier
        XCTAssertEqual(version, Schema.Version(5, 0, 0))
    }

    func test_v5DeclaresThreeModelTypes() {
        let models = CatchSchemaV5.models
        XCTAssertEqual(models.count, 3)
        XCTAssertTrue(models.contains(where: { $0 == Cat.self }))
        XCTAssertTrue(models.contains(where: { $0 == Encounter.self }))
        XCTAssertTrue(models.contains(where: { $0 == UserProfile.self }))
    }

    func test_v5ModelContainerCanBeCreated() throws {
        let schema = Schema(versionedSchema: CatchSchemaV5.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 3)
    }

    // MARK: - Migration Plan

    func test_migrationPlanIncludesFiveSchemas() {
        let schemas = CatchMigrationPlan.schemas
        XCTAssertEqual(schemas.count, 5)
        XCTAssertTrue(schemas[0] == CatchSchemaV1.self)
        XCTAssertTrue(schemas[1] == CatchSchemaV2.self)
        XCTAssertTrue(schemas[2] == CatchSchemaV3.self)
        XCTAssertTrue(schemas[3] == CatchSchemaV4.self)
        XCTAssertTrue(schemas[4] == CatchSchemaV5.self)
    }

    func test_migrationPlanHasFourStages() {
        XCTAssertEqual(CatchMigrationPlan.stages.count, 4)
    }

    func test_v1ModelContainerCanBeCreated() throws {
        let schema = Schema(versionedSchema: CatchSchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 3)
    }
}
