import Foundation

/// Row returned from the `user_blocks` table.
public struct UserBlock: Codable, Sendable, Identifiable {
    public let id: UUID
    public let blockerID: UUID
    public let blockedID: UUID
    public let createdAt: Date

    public init(id: UUID, blockerID: UUID, blockedID: UUID, createdAt: Date) {
        self.id = id
        self.blockerID = blockerID
        self.blockedID = blockedID
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case blockerID = "blocker_id"
        case blockedID = "blocked_id"
        case createdAt = "created_at"
    }
}

/// Payload for inserting a block row.
public struct UserBlockInsertPayload: Codable, Sendable {
    public let blockerID: String
    public let blockedID: String

    public init(blockerID: String, blockedID: String) {
        self.blockerID = blockerID
        self.blockedID = blockedID
    }

    enum CodingKeys: String, CodingKey {
        case blockerID = "blocker_id"
        case blockedID = "blocked_id"
    }
}
