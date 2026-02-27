import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockUserBrowseService: UserBrowseService {
    private(set) var isLoading = false
    private(set) var error: UserBrowseError?

    private(set) var fetchUserDataCalls: [String] = []
    private(set) var fetchDisplayNameCalls: [String] = []
    private(set) var clearCacheCalls = 0

    var fetchUserDataResult: Result<UserBrowseData, UserBrowseError> = .failure(.userNotFound)
    var fetchUserDataResults: [String: Result<UserBrowseData, UserBrowseError>] = [:]
    var cachedDataResult: UserBrowseData?
    var displayNameResult: String?
    var profileResult: CloudUserProfile?
    private(set) var fetchProfileCalls: [String] = []

    func fetchUserData(userID: String) async throws -> UserBrowseData {
        fetchUserDataCalls.append(userID)
        if let perUserResult = fetchUserDataResults[userID] {
            return try perUserResult.get()
        }
        return try fetchUserDataResult.get()
    }

    func cachedData(for userID: String) -> UserBrowseData? {
        cachedDataResult
    }

    func fetchDisplayName(userID: String) async -> String? {
        fetchDisplayNameCalls.append(userID)
        return displayNameResult
    }

    func fetchProfile(userID: String) async -> CloudUserProfile? {
        fetchProfileCalls.append(userID)
        return profileResult
    }

    func clearCache() {
        clearCacheCalls += 1
    }

    func reset() {
        isLoading = false
        error = nil
        fetchUserDataCalls = []
        fetchDisplayNameCalls = []
        clearCacheCalls = 0
        fetchUserDataResult = .failure(.userNotFound)
        fetchUserDataResults = [:]
        cachedDataResult = nil
        displayNameResult = nil
        profileResult = nil
        fetchProfileCalls = []
    }
}
