import Foundation

/// Data-access layer for the social feed stored in Supabase.
@MainActor
public protocol SupabaseFeedRepository: Sendable {
    /// Fetches a page of feed encounters for the given followed user IDs.
    /// Returns encounters ordered by date descending, with joined cat and profile data.
    /// - Parameters:
    ///   - followedUserIDs: The user IDs whose encounters to fetch.
    ///   - limit: Maximum number of rows to return.
    ///   - cursor: ISO 8601 date string for cursor-based pagination (exclusive upper bound).
    func fetchFeed(
        followedUserIDs: [String],
        limit: Int,
        cursor: String?
    ) async throws -> [SupabaseFeedRow]
}
