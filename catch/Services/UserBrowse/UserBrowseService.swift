import Foundation

@MainActor
protocol UserBrowseService: Observable, Sendable {
    var isLoading: Bool { get }
    var error: UserBrowseError? { get }

    func fetchUserData(userID: String) async throws -> UserBrowseData
    func cachedData(for userID: String) -> UserBrowseData?
    func fetchDisplayName(userID: String) async -> String?
    func fetchProfile(userID: String) async -> CloudUserProfile?
    func clearCache()
}
