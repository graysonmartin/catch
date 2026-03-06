import Foundation
import Observation
import Supabase

@Observable
@MainActor
public final class SupabaseClientProvider: SupabaseClientProviding, @unchecked Sendable {
    @ObservationIgnored
    public let client: SupabaseClient

    public init(
        url: URL = SupabaseConfig.url,
        key: String = SupabaseConfig.anonKey
    ) {
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
