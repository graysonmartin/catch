import Foundation

/// Data-access layer for user blocks stored in Supabase.
@MainActor
public protocol BlockRepository: Sendable {
    func insertBlock(payload: UserBlockInsertPayload) async throws -> UserBlock
    func deleteBlock(blockerID: String, blockedID: String) async throws
    func fetchBlocks(blockerID: String) async throws -> [UserBlock]
}
