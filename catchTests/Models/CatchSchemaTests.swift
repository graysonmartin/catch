import XCTest
import SwiftData

@MainActor
final class CatchSchemaTests: XCTestCase {

    func test_schemaDeclaresThreeEntities() {
        let schema = CatchSchema.current
        XCTAssertEqual(schema.entities.count, 3)
    }

    func test_modelContainerCanBeCreated() throws {
        let schema = CatchSchema.current
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        XCTAssertEqual(container.schema.entities.count, 3)
    }
}
