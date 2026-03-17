import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseEncounterRepository: SupabaseEncounterRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let tableName = "encounters"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseEncounterRepository

    public func fetchEncounter(id: String) async throws -> SupabaseEncounter? {
        let response: [SupabaseEncounter] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    public func fetchEncounters(ownerID: String) async throws -> [SupabaseEncounter] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("owner_id", value: ownerID)
            .order("date", ascending: false)
            .execute()
            .value
    }

    public func fetchEncounters(catID: String) async throws -> [SupabaseEncounter] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("cat_id", value: catID)
            .order("date", ascending: false)
            .execute()
            .value
    }

    public func insertEncounter(_ payload: SupabaseEncounterInsertPayload) async throws -> SupabaseEncounter {
        try await clientProvider.client
            .from(Self.tableName)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func updateEncounter(
        id: String,
        _ payload: SupabaseEncounterUpdatePayload
    ) async throws -> SupabaseEncounter {
        try await clientProvider.client
            .from(Self.tableName)
            .update(payload)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    public func deleteEncounter(id: String) async throws {
        try await clientProvider.client
            .from(Self.tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Paginated Feed

    /// Columns selected from the joined query. Selects encounter fields plus nested cat.
    private static let feedSelect = """
        id, owner_id, cat_id, date, location_name, location_lat, location_lng, \
        notes, photo_urls, like_count, comment_count, created_at, \
        cats!inner(id, name, breed, estimated_age, location_name, location_lat, location_lng, notes, is_owned, photo_urls, created_at)
        """

    public func fetchEncounterFeed(
        ownerID: String,
        limit: Int,
        cursor: String?
    ) async throws -> [SupabaseEncounterFeedRow] {
        var filterBuilder = clientProvider.client
            .from(Self.tableName)
            .select(Self.feedSelect)
            .eq("owner_id", value: ownerID)

        if let cursor {
            filterBuilder = filterBuilder.lt("date", value: cursor)
        }

        let rows: [SupabaseEncounterFeedRow] = try await filterBuilder
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows
    }
}
