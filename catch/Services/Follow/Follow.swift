import Foundation

struct Follow: Sendable, Equatable, Identifiable {
    let id: String
    let followerID: String
    let followeeID: String
    let status: FollowStatus
    let createdAt: Date

    var isActive: Bool { status == .active }
    var isPending: Bool { status == .pending }
}
