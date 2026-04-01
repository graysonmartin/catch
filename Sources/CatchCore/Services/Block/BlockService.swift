import Foundation

@MainActor
public protocol BlockService: Observable, Sendable {
    var blockedUserIDs: Set<String> { get }
    func blockUser(_ targetID: String) async throws
    func unblockUser(_ targetID: String) async throws
    func isBlocked(_ targetID: String) -> Bool
    func loadBlocks() async throws
}
