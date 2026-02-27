import Foundation

public struct UserBrowseData: Sendable {
    public let profile: CloudUserProfile
    public let cats: [CloudCat]
    public let encounters: [CloudEncounter]
    public let followerCount: Int
    public let followingCount: Int
    public let fetchedAt: Date

    private static let cacheTTL: TimeInterval = 300 // 5 minutes

    public var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > Self.cacheTTL
    }

    public init(
        profile: CloudUserProfile,
        cats: [CloudCat],
        encounters: [CloudEncounter],
        followerCount: Int,
        followingCount: Int,
        fetchedAt: Date
    ) {
        self.profile = profile
        self.cats = cats
        self.encounters = encounters
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.fetchedAt = fetchedAt
    }
}
