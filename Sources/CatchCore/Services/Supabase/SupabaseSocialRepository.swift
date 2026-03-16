import Foundation

/// Data-access layer for encounter likes and comments stored in Supabase.
@MainActor
public protocol SupabaseSocialRepository: Sendable {

    // MARK: - Likes

    func insertLike(encounterID: String, userID: String) async throws -> SupabaseLike
    func deleteLike(encounterID: String, userID: String) async throws
    func fetchLikes(encounterID: String, limit: Int, offset: Int) async throws -> [SupabaseLikeWithProfile]
    func fetchUserLike(encounterID: String, userID: String) async throws -> SupabaseLike?

    // MARK: - Comments

    func insertComment(encounterID: String, userID: String, text: String) async throws -> SupabaseCommentWithProfile
    func deleteComment(id: String) async throws
    func fetchComments(encounterID: String, limit: Int, offset: Int) async throws -> [SupabaseCommentWithProfile]

    // MARK: - Counts (denormalized on encounters table)

    func fetchInteractionCounts(encounterIDs: [String]) async throws -> [SupabaseEncounterCounts]

    // MARK: - User Likes (batch check)

    func fetchUserLikes(encounterIDs: [String], userID: String) async throws -> [SupabaseLike]
}
