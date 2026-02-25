import Foundation

struct UserBrowseData: Sendable {
    let profile: CloudUserProfile
    let cats: [CloudCat]
    let encounters: [CloudEncounter]
    let fetchedAt: Date

    private static let cacheTTL: TimeInterval = 300 // 5 minutes

    var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > Self.cacheTTL
    }
}
