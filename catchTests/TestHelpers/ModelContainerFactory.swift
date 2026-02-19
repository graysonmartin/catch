import SwiftData

extension ModelContainer {
    @MainActor
    static func forTesting() throws -> ModelContainer {
        let schema = Schema([Cat.self, Encounter.self, CareEntry.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}
