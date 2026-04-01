import Foundation
import Supabase

@MainActor
public final class DefaultBlockRepository: BlockRepository, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private static let table = "user_blocks"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    public func insertBlock(payload: UserBlockInsertPayload) async throws -> UserBlock {
        try await clientProvider.client
            .from(Self.table)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    public func deleteBlock(blockerID: String, blockedID: String) async throws {
        try await clientProvider.client
            .from(Self.table)
            .delete()
            .eq("blocker_id", value: blockerID)
            .eq("blocked_id", value: blockedID)
            .execute()
    }

    public func fetchBlocks(blockerID: String) async throws -> [UserBlock] {
        try await clientProvider.client
            .from(Self.table)
            .select()
            .eq("blocker_id", value: blockerID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
