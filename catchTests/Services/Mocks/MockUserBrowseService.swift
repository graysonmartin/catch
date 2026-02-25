import Foundation
import Observation

@Observable
@MainActor
final class MockUserBrowseService: UserBrowseService {
    private(set) var isLoading = false
    private(set) var error: UserBrowseError?

    private(set) var fetchUserDataCalls: [String] = []
    private(set) var fetchDisplayNameCalls: [String] = []
    private(set) var clearCacheCalls = 0

    var fetchUserDataResult: Result<UserBrowseData, UserBrowseError> = .failure(.userNotFound)
    var cachedDataResult: UserBrowseData?
    var displayNameResult: String?

    func fetchUserData(userID: String) async throws -> UserBrowseData {
        fetchUserDataCalls.append(userID)
        return try fetchUserDataResult.get()
    }

    func cachedData(for userID: String) -> UserBrowseData? {
        cachedDataResult
    }

    func fetchDisplayName(userID: String) async -> String? {
        fetchDisplayNameCalls.append(userID)
        return displayNameResult
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
        cachedDataResult = nil
        displayNameResult = nil
    }
}
