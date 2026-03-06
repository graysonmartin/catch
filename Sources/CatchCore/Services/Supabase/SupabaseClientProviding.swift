import Observation
import Supabase

@MainActor
public protocol SupabaseClientProviding: Observable, Sendable {
    var client: SupabaseClient { get }
}
