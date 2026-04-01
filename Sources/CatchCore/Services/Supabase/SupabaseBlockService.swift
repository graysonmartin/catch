import Foundation
import Observation

@Observable
@MainActor
public final class SupabaseBlockService: BlockService {
    public private(set) var blockedUserIDs: Set<String> = []

    private let repository: any BlockRepository
    private let getCurrentUserID: () -> String?
    private let rateLimiter: any RateLimiting

    public init(
        repository: any BlockRepository,
        getCurrentUserID: @escaping @Sendable () -> String?,
        rateLimiter: any RateLimiting = RateLimiter()
    ) {
        self.repository = repository
        self.getCurrentUserID = getCurrentUserID
        self.rateLimiter = rateLimiter
    }

    public func blockUser(_ targetID: String) async throws {
        guard let userID = getCurrentUserID() else {
            throw BlockError.notSignedIn
        }

        guard userID != targetID else {
            throw BlockError.cannotBlockSelf
        }

        guard !blockedUserIDs.contains(targetID) else {
            throw BlockError.alreadyBlocked
        }

        try rateLimiter.checkAllowed(.block)

        let payload = UserBlockInsertPayload(blockerID: userID, blockedID: targetID)

        do {
            _ = try await repository.insertBlock(payload: payload)
            rateLimiter.recordAction(.block)
            blockedUserIDs.insert(targetID)
        } catch {
            throw BlockError.networkError(error.localizedDescription)
        }
    }

    public func unblockUser(_ targetID: String) async throws {
        guard let userID = getCurrentUserID() else {
            throw BlockError.notSignedIn
        }

        try rateLimiter.checkAllowed(.unblock)

        do {
            try await repository.deleteBlock(blockerID: userID, blockedID: targetID)
            rateLimiter.recordAction(.unblock)
            blockedUserIDs.remove(targetID)
        } catch {
            throw BlockError.networkError(error.localizedDescription)
        }
    }

    public func isBlocked(_ targetID: String) -> Bool {
        blockedUserIDs.contains(targetID)
    }

    public func loadBlocks() async throws {
        guard let userID = getCurrentUserID() else { return }

        do {
            let blocks = try await repository.fetchBlocks(blockerID: userID)
            blockedUserIDs = Set(blocks.map { $0.blockedID.uuidString.lowercased() })
        } catch {
            throw BlockError.networkError(error.localizedDescription)
        }
    }
}
