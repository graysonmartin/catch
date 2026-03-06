import Foundation
import Observation
import Supabase
@testable import CatchCore

@Observable
@MainActor
final class MockSupabaseClientProvider: SupabaseClientProviding, @unchecked Sendable {
    @ObservationIgnored
    let client: SupabaseClient

    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://test.supabase.co")!,
            supabaseKey: "test-anon-key"
        )
    }
}
