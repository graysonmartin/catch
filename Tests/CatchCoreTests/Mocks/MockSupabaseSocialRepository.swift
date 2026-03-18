import Foundation
@testable import CatchCore

@MainActor
final class MockSupabaseSocialRepository: SupabaseSocialRepository {

    // MARK: - Call Tracking

    var insertLikeCalls: [(encounterID: String, userID: String)] = []
    var deleteLikeCalls: [(encounterID: String, userID: String)] = []
    var fetchLikesCalls: [(encounterID: String, limit: Int, offset: Int)] = []
    var fetchUserLikeCalls: [(encounterID: String, userID: String)] = []
    var insertCommentCalls: [(encounterID: String, userID: String, text: String)] = []
    var deleteCommentCalls: [String] = []
    var fetchCommentsCalls: [(encounterID: String, limit: Int, offset: Int)] = []
    var fetchInteractionCountsCalls: [[String]] = []
    var fetchUserLikesCalls: [(encounterIDs: [String], userID: String)] = []

    // MARK: - Stubbed Results

    var insertLikeResult: SupabaseLike?
    var insertLikeError: (any Error)?
    var deleteLikeError: (any Error)?
    var fetchLikesResult: [SupabaseLikeWithProfile] = []
    var fetchUserLikeResult: SupabaseLike?
    var insertCommentResult: SupabaseCommentWithProfile?
    var insertCommentError: (any Error)?
    var deleteCommentError: (any Error)?
    var fetchCommentsResult: [SupabaseCommentWithProfile] = []
    var fetchInteractionCountsResult: [SupabaseEncounterCounts] = []
    var fetchUserLikesResult: [SupabaseLike] = []
    var error: (any Error)?

    // MARK: - Likes

    func insertLike(encounterID: String, userID: String) async throws -> SupabaseLike {
        insertLikeCalls.append((encounterID, userID))
        if let insertLikeError { throw insertLikeError }
        if let error { throw error }
        guard let result = insertLikeResult else {
            throw NSError(domain: "MockSupabaseSocialRepository", code: 0)
        }
        return result
    }

    func deleteLike(encounterID: String, userID: String) async throws {
        deleteLikeCalls.append((encounterID, userID))
        if let deleteLikeError { throw deleteLikeError }
        if let error { throw error }
    }

    func fetchLikes(encounterID: String, limit: Int, offset: Int) async throws -> [SupabaseLikeWithProfile] {
        fetchLikesCalls.append((encounterID, limit, offset))
        if let error { throw error }
        return fetchLikesResult
    }

    func fetchUserLike(encounterID: String, userID: String) async throws -> SupabaseLike? {
        fetchUserLikeCalls.append((encounterID, userID))
        if let error { throw error }
        return fetchUserLikeResult
    }

    // MARK: - Comments

    func insertComment(encounterID: String, userID: String, text: String) async throws -> SupabaseCommentWithProfile {
        insertCommentCalls.append((encounterID, userID, text))
        if let insertCommentError { throw insertCommentError }
        if let error { throw error }
        guard let result = insertCommentResult else {
            throw NSError(domain: "MockSupabaseSocialRepository", code: 0)
        }
        return result
    }

    func deleteComment(id: String) async throws {
        deleteCommentCalls.append(id)
        if let deleteCommentError { throw deleteCommentError }
        if let error { throw error }
    }

    func fetchComments(encounterID: String, limit: Int, offset: Int) async throws -> [SupabaseCommentWithProfile] {
        fetchCommentsCalls.append((encounterID, limit, offset))
        if let error { throw error }
        return fetchCommentsResult
    }

    // MARK: - Counts

    func fetchInteractionCounts(encounterIDs: [String]) async throws -> [SupabaseEncounterCounts] {
        fetchInteractionCountsCalls.append(encounterIDs)
        if let error { throw error }
        return fetchInteractionCountsResult
    }

    // MARK: - User Likes (batch)

    func fetchUserLikes(encounterIDs: [String], userID: String) async throws -> [SupabaseLike] {
        fetchUserLikesCalls.append((encounterIDs, userID))
        if let error { throw error }
        return fetchUserLikesResult
    }
}

// MARK: - Test Fixtures

extension SupabaseLike {
    static func fixture(
        id: UUID = UUID(),
        encounterID: UUID = UUID(),
        userID: UUID = UUID(),
        createdAt: Date = Date()
    ) -> SupabaseLike {
        SupabaseLike(id: id, encounterID: encounterID, userID: userID, createdAt: createdAt)
    }
}

extension SupabaseLikeWithProfile {
    static func fixture(
        id: UUID = UUID(),
        encounterID: UUID = UUID(),
        userID: UUID = UUID(),
        createdAt: Date = Date(),
        displayName: String = "TestUser",
        username: String? = nil
    ) -> SupabaseLikeWithProfile {
        SupabaseLikeWithProfile(
            id: id,
            encounterID: encounterID,
            userID: userID,
            createdAt: createdAt,
            profiles: .init(displayName: displayName, username: username)
        )
    }
}

extension SupabaseCommentWithProfile {
    static func fixture(
        id: UUID = UUID(),
        encounterID: UUID = UUID(),
        userID: UUID = UUID(),
        text: String = "nice cat",
        createdAt: Date = Date(),
        displayName: String = "TestUser",
        avatarURL: String? = nil
    ) -> SupabaseCommentWithProfile {
        SupabaseCommentWithProfile(
            id: id,
            encounterID: encounterID,
            userID: userID,
            text: text,
            createdAt: createdAt,
            profiles: .init(displayName: displayName, avatarURL: avatarURL)
        )
    }
}

extension SupabaseEncounterCounts {
    static func fixture(
        id: UUID = UUID(),
        likeCount: Int = 0,
        commentCount: Int = 0
    ) -> SupabaseEncounterCounts {
        SupabaseEncounterCounts(id: id, likeCount: likeCount, commentCount: commentCount)
    }
}
