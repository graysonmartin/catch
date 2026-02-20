import SwiftUI
import SwiftData

@main
struct catchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AppleAuthService()
    @State private var followService = CKFollowService()
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema(versionedSchema: CatchSchemaV3.self)
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: CatchMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(authService)
                    .environment(followService)
                    .task {
                        await authService.checkCredentialState()
                    }
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
