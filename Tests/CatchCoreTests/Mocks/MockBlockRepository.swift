import Foundation
@testable import CatchCore

@MainActor
final class MockBlockRepository: BlockRepository {

    // MARK: - Call Tracking

    var insertBlockCalls: [UserBlockInsertPayload] = []
    var deleteBlockCalls: [(blockerID: String, blockedID: String)] = []
    var fetchBlocksCalls: [String] = []

    // MARK: - Stubbed Results

    var insertBlockResult: UserBlock?
    var insertBlockError: (any Error)?
    var deleteBlockError: (any Error)?
    var fetchBlocksResult: [UserBlock] = []
    var fetchBlocksError: (any Error)?

    // MARK: - Protocol

    func insertBlock(payload: UserBlockInsertPayload) async throws -> UserBlock {
        insertBlockCalls.append(payload)
        if let insertBlockError { throw insertBlockError }
        guard let result = insertBlockResult else {
            throw NSError(domain: "MockBlockRepository", code: 0)
        }
        return result
    }

    func deleteBlock(blockerID: String, blockedID: String) async throws {
        deleteBlockCalls.append((blockerID, blockedID))
        if let deleteBlockError { throw deleteBlockError }
    }

    func fetchBlocks(blockerID: String) async throws -> [UserBlock] {
        fetchBlocksCalls.append(blockerID)
        if let fetchBlocksError { throw fetchBlocksError }
        return fetchBlocksResult
    }
}

// MARK: - Test Fixtures

extension UserBlock {
    static func fixture(
        id: UUID = UUID(),
        blockerID: UUID = UUID(),
        blockedID: UUID = UUID(),
        createdAt: Date = Date()
    ) -> UserBlock {
        UserBlock(id: id, blockerID: blockerID, blockedID: blockedID, createdAt: createdAt)
    }
}
