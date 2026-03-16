import Foundation

public struct Follow: Sendable, Equatable, Identifiable {
    public let id: String
    public let followerID: String
    public let followeeID: String
    public let status: FollowStatus
    public let createdAt: Date
    public let followerDisplayName: String?

    public var isActive: Bool { status == .active }
    public var isPending: Bool { status == .pending }

    public init(
        id: String,
        followerID: String,
        followeeID: String,
        status: FollowStatus,
        createdAt: Date,
        followerDisplayName: String? = nil
    ) {
        self.id = id
        self.followerID = followerID
        self.followeeID = followeeID
        self.status = status
        self.createdAt = createdAt
        self.followerDisplayName = followerDisplayName
    }
}
