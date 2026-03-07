import Foundation
import Supabase

@MainActor
public final class DefaultSupabaseFollowRepository: SupabaseFollowRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let tableName = "follows"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseFollowRepository

    public func fetchFollow(followerID: String, followeeID: String) async throws -> SupabaseFollow? {
        let response: [SupabaseFollow] = try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("follower_id", value: followerID)
            .eq("followee_id", value: followeeID)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    public func fetchFollowers(userID: String, status: String, limit: Int, offset: Int) async throws -> [SupabaseFollow] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("followee_id", value: userID)
            .eq("status", value: status)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    public func fetchFollowing(userID: String, status: String, limit: Int, offset: Int) async throws -> [SupabaseFollow] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("follower_id", value: userID)
            .eq("status", value: status)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    public func fetchPendingIncoming(userID: String) async throws -> [SupabaseFollow] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("followee_id", value: userID)
            .eq("status", value: FollowStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    public func fetchPendingOutgoing(userID: String) async throws -> [SupabaseFollow] {
        try await clientProvider.client
            .from(Self.tableName)
            .select()
            .eq("follower_id", value: userID)
            .eq("status", value: FollowStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    public func insertFollow(_ payload: SupabaseFollowInsertPayload) async throws -> SupabaseFollow {
        try await clientProvider.client
            .from(Self.tableName)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func updateFollowStatus(id: String, status: String) async throws -> SupabaseFollow {
        try await clientProvider.client
            .from(Self.tableName)
            .update(SupabaseFollowUpdatePayload(status: status))
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    public func deleteFollow(id: String) async throws {
        try await clientProvider.client
            .from(Self.tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    public func countFollowers(userID: String) async throws -> Int {
        let response: [SupabaseFollow] = try await clientProvider.client
            .from(Self.tableName)
            .select("id")
            .eq("followee_id", value: userID)
            .eq("status", value: FollowStatus.active.rawValue)
            .execute()
            .value
        return response.count
    }

    public func countFollowing(userID: String) async throws -> Int {
        let response: [SupabaseFollow] = try await clientProvider.client
            .from(Self.tableName)
            .select("id")
            .eq("follower_id", value: userID)
            .eq("status", value: FollowStatus.active.rawValue)
            .execute()
            .value
        return response.count
    }
}
