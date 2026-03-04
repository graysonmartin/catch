import Foundation

/// Lightweight model representing a user who liked an encounter.
/// Used to populate the "liked by" list without fetching full profile data upfront.
public struct LikedByUser: Sendable, Equatable, Identifiable {
    public let id: String
    public let userID: String
    public let displayName: String
    public let username: String?
    public let likedAt: Date

    public init(
        id: String,
        userID: String,
        displayName: String,
        username: String?,
        likedAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.displayName = displayName
        self.username = username
        self.likedAt = likedAt
    }
}
