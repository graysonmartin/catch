import Foundation

@MainActor
public protocol SupabaseFollowRepository: Sendable {
    func fetchFollow(followerID: String, followeeID: String) async throws -> SupabaseFollow?
    func fetchFollowers(userID: String, status: String, limit: Int, offset: Int) async throws -> [SupabaseFollow]
    func fetchFollowing(userID: String, status: String, limit: Int, offset: Int) async throws -> [SupabaseFollow]
    func fetchPendingIncoming(userID: String) async throws -> [SupabaseFollowWithProfile]
    func fetchPendingOutgoing(userID: String) async throws -> [SupabaseFollow]
    func insertFollow(_ payload: SupabaseFollowInsertPayload) async throws -> SupabaseFollow
    func updateFollowStatus(id: String, status: String) async throws -> SupabaseFollow
    func deleteFollow(id: String) async throws
    func countFollowers(userID: String) async throws -> Int
    func countFollowing(userID: String) async throws -> Int
}
