import SwiftUI
import SwiftData

@main
struct catchApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var authService = AppleAuthService()
    @State private var followService = CKFollowService()
    @State private var catRepository = CKCatRepository()
    @State private var encounterRepository = CKEncounterRepository()
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema(versionedSchema: CatchSchemaV2.self)
            let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
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
                    .environment(catRepository)
                    .environment(encounterRepository)
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
