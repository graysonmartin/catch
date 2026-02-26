import SwiftData

extension ModelContainer {
    @MainActor
    static func forTesting() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CatchSchemaV6.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}
