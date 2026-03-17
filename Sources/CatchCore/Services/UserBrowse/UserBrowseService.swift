import Foundation

@MainActor
public protocol UserBrowseService: Observable, Sendable {
    var isLoading: Bool { get }
    var error: UserBrowseError? { get }

    func fetchUserData(userID: String) async throws -> UserBrowseData
    func cachedData(for userID: String) -> UserBrowseData?
    func fetchDisplayName(userID: String) async -> String?
    func cachedDisplayName(for userID: String) -> String?
    func batchFetchDisplayNames(userIDs: [String]) async -> [String: String]
    func batchFetchProfiles(userIDs: [String]) async -> [String: CloudUserProfile]
    func fetchProfile(userID: String) async -> CloudUserProfile?
    func cachedProfile(for userID: String) -> CloudUserProfile?
    func clearCache()
}
