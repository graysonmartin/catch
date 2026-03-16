import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseSocialRepository: SupabaseSocialRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let likesTable = "encounter_likes"
    private static let commentsTable = "encounter_comments"
    private static let encountersTable = "encounters"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - Likes

    public func insertLike(encounterID: String, userID: String) async throws -> SupabaseLike {
        let payload = SupabaseLikeInsertPayload(encounterID: encounterID, userID: userID)
        return try await clientProvider.client
            .from(Self.likesTable)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func deleteLike(encounterID: String, userID: String) async throws {
        try await clientProvider.client
            .from(Self.likesTable)
            .delete()
            .eq("encounter_id", value: encounterID)
            .eq("user_id", value: userID)
            .execute()
    }

    public func fetchLikes(
        encounterID: String,
        limit: Int,
        offset: Int
    ) async throws -> [SupabaseLikeWithProfile] {
        try await clientProvider.client
            .from(Self.likesTable)
            .select("*, profiles!user_id(display_name, username)")
            .eq("encounter_id", value: encounterID)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    public func fetchUserLike(
        encounterID: String,
        userID: String
    ) async throws -> SupabaseLike? {
        let response: [SupabaseLike] = try await clientProvider.client
            .from(Self.likesTable)
            .select()
            .eq("encounter_id", value: encounterID)
            .eq("user_id", value: userID)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    // MARK: - Comments

    public func insertComment(
        encounterID: String,
        userID: String,
        text: String
    ) async throws -> SupabaseCommentWithProfile {
        let payload = SupabaseCommentInsertPayload(
            encounterID: encounterID,
            userID: userID,
            text: text
        )
        return try await clientProvider.client
            .from(Self.commentsTable)
            .insert(payload)
            .select("*, profiles!user_id(display_name)")
            .single()
            .execute()
            .value
    }

    public func deleteComment(id: String) async throws {
        try await clientProvider.client
            .from(Self.commentsTable)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    public func fetchComments(
        encounterID: String,
        limit: Int,
        offset: Int
    ) async throws -> [SupabaseCommentWithProfile] {
        try await clientProvider.client
            .from(Self.commentsTable)
            .select("*, profiles!user_id(display_name)")
            .eq("encounter_id", value: encounterID)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    // MARK: - Counts

    public func fetchInteractionCounts(
        encounterIDs: [String]
    ) async throws -> [SupabaseEncounterCounts] {
        try await clientProvider.client
            .from(Self.encountersTable)
            .select("id, like_count, comment_count")
            .in("id", values: encounterIDs)
            .execute()
            .value
    }

    // MARK: - User Likes (batch)

    public func fetchUserLikes(
        encounterIDs: [String],
        userID: String
    ) async throws -> [SupabaseLike] {
        try await clientProvider.client
            .from(Self.likesTable)
            .select()
            .in("encounter_id", values: encounterIDs)
            .eq("user_id", value: userID)
            .execute()
            .value
    }
}
