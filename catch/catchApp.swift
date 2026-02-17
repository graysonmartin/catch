import SwiftUI
import SwiftData

@main
struct catchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Cat.self)
    }
}
