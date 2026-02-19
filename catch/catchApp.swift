import SwiftUI
import SwiftData

@main
struct catchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Cat.self, UserProfile.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    #if DEBUG
                    .task {
                        DataSeeder.seedIfEmpty(context: modelContainer.mainContext)
                    }
                    #endif
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}
