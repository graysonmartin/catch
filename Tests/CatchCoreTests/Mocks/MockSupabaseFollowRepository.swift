import Foundation
@testable import CatchCore

@MainActor
final class MockSupabaseFollowRepository: SupabaseFollowRepository {
    var fetchFollowCalls: [(followerID: String, followeeID: String)] = []
    var fetchFollowersCalls: [(userID: String, status: String, limit: Int, offset: Int)] = []
    var fetchFollowingCalls: [(userID: String, status: String, limit: Int, offset: Int)] = []
    var fetchPendingIncomingCalls: [String] = []
    var fetchPendingOutgoingCalls: [String] = []
    var insertFollowCalls: [SupabaseFollowInsertPayload] = []
    var updateFollowStatusCalls: [(id: String, status: String)] = []
    var deleteFollowCalls: [String] = []
    var countFollowersCalls: [String] = []
    var countFollowingCalls: [String] = []

    var fetchFollowResult: SupabaseFollow?
    var fetchFollowersResult: [SupabaseFollow] = []
    var fetchFollowingResult: [SupabaseFollow] = []
    var fetchPendingIncomingResult: [SupabaseFollow] = []
    var fetchPendingOutgoingResult: [SupabaseFollow] = []
    var insertFollowResult: SupabaseFollow?
    var updateFollowStatusResult: SupabaseFollow?
    var deleteFollowError: (any Error)?
    var countFollowersResult: Int = 0
    var countFollowingResult: Int = 0
    var error: (any Error)?

    func fetchFollow(followerID: String, followeeID: String) async throws -> SupabaseFollow? {
        fetchFollowCalls.append((followerID, followeeID))
        if let error { throw error }
        return fetchFollowResult
    }

    func fetchFollowers(userID: String, status: String, limit: Int, offset: Int) async throws -> [SupabaseFollow] {
        fetchFollowersCalls.append((userID, status, limit, offset))
        if let error { throw error }
        return fetchFollowersResult
    }

    func fetchFollowing(userID: String, status: String, limit: Int, offset: Int) async throws -> [SupabaseFollow] {
        fetchFollowingCalls.append((userID, status, limit, offset))
        if let error { throw error }
        return fetchFollowingResult
    }

    func fetchPendingIncoming(userID: String) async throws -> [SupabaseFollow] {
        fetchPendingIncomingCalls.append(userID)
        if let error { throw error }
        return fetchPendingIncomingResult
    }

    func fetchPendingOutgoing(userID: String) async throws -> [SupabaseFollow] {
        fetchPendingOutgoingCalls.append(userID)
        if let error { throw error }
        return fetchPendingOutgoingResult
    }

    func insertFollow(_ payload: SupabaseFollowInsertPayload) async throws -> SupabaseFollow {
        insertFollowCalls.append(payload)
        if let error { throw error }
        guard let result = insertFollowResult else {
            throw NSError(domain: "MockSupabaseFollowRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "no stubbed insert result"])
        }
        return result
    }

    func updateFollowStatus(id: String, status: String) async throws -> SupabaseFollow {
        updateFollowStatusCalls.append((id, status))
        if let error { throw error }
        guard let result = updateFollowStatusResult else {
            throw NSError(domain: "MockSupabaseFollowRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "no stubbed update result"])
        }
        return result
    }

    func deleteFollow(id: String) async throws {
        deleteFollowCalls.append(id)
        if let deleteFollowError { throw deleteFollowError }
        if let error { throw error }
    }

    func countFollowers(userID: String) async throws -> Int {
        countFollowersCalls.append(userID)
        if let error { throw error }
        return countFollowersResult
    }

    func countFollowing(userID: String) async throws -> Int {
        countFollowingCalls.append(userID)
        if let error { throw error }
        return countFollowingResult
    }
}

// MARK: - Test Factory

extension SupabaseFollow {
    static func fixture(
        id: UUID = UUID(),
        followerID: UUID = UUID(),
        followeeID: UUID = UUID(),
        status: String = "active",
        createdAt: Date = Date()
    ) -> SupabaseFollow {
        SupabaseFollow(
            id: id,
            followerID: followerID,
            followeeID: followeeID,
            status: status,
            createdAt: createdAt
        )
    }
}
