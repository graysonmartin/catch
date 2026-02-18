import SwiftUI
import SwiftData

@main
struct catchApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Cat.self)
            #if DEBUG
            DataSeeder.seedIfEmpty(context: modelContainer.mainContext)
            #endif
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
