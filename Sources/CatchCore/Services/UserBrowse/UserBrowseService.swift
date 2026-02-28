import Foundation

@MainActor
public protocol UserBrowseService: Observable, Sendable {
    var isLoading: Bool { get }
    var error: UserBrowseError? { get }

    func fetchUserData(userID: String) async throws -> UserBrowseData
    func cachedData(for userID: String) -> UserBrowseData?
    func fetchDisplayName(userID: String) async -> String?
    func fetchDisplayNames(userIDs: [String]) async -> [String: String]
    func fetchProfile(userID: String) async -> CloudUserProfile?
    func clearCache()
}
