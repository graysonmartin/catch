import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseFeedRepository: SupabaseFeedRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding

    private static let encountersTable = "encounters"

    /// Columns selected from the joined query. Selects encounter fields plus nested cat and profile.
    private static let feedSelect = """
        id, owner_id, cat_id, date, location_name, location_lat, location_lng, \
        notes, photo_urls, like_count, comment_count, created_at, \
        cats!inner(id, name, breed, estimated_age, location_name, location_lat, location_lng, notes, is_owned, photo_urls, created_at), \
        profiles!inner(id, display_name, username, bio, is_private, avatar_url)
        """

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseFeedRepository

    public func fetchFeed(
        followedUserIDs: [String],
        limit: Int,
        cursor: String?
    ) async throws -> [SupabaseFeedRow] {
        guard !followedUserIDs.isEmpty else { return [] }

        var filterBuilder = clientProvider.client
            .from(Self.encountersTable)
            .select(Self.feedSelect)
            .in("owner_id", values: followedUserIDs)

        if let cursor {
            filterBuilder = filterBuilder.lt("date", value: cursor)
        }

        let rows: [SupabaseFeedRow] = try await filterBuilder
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows
    }
}
