import Foundation
@testable import CatchCore

@MainActor
final class MockCloudKitService: CloudKitService {
    var savedProfiles: [(appleUserID: String, displayName: String, bio: String, username: String?, isPrivate: Bool, avatarData: Data?)] = []
    var fetchedAppleUserIDs: [String] = []
    var deletedRecordNames: [String] = []

    var saveResult: Result<String, any Error> = .success("mock-record-name")
    var fetchResult: CloudUserProfile?
    var fetchResultsByUserID: [String: CloudUserProfile] = [:]
    var deleteError: (any Error)?
    var searchUsersResult: [CloudUserProfile] = []
    private(set) var searchUsersCalls: [String] = []
    var usernameAvailabilityResult: Bool = true
    private(set) var usernameAvailabilityCalls: [String] = []

    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String?,
        isPrivate: Bool,
        avatarData: Data?
    ) async throws -> String {
        savedProfiles.append((appleUserID, displayName, bio, username, isPrivate, avatarData))
        return try saveResult.get()
    }

    func fetchUserProfile(appleUserID: String) async throws -> CloudUserProfile? {
        fetchedAppleUserIDs.append(appleUserID)
        return fetchResultsByUserID[appleUserID] ?? fetchResult
    }

    func deleteUserProfile(recordName: String) async throws {
        deletedRecordNames.append(recordName)
        if let error = deleteError { throw error }
    }

    func searchUsers(query: String) async throws -> [CloudUserProfile] {
        searchUsersCalls.append(query)
        return searchUsersResult
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        usernameAvailabilityCalls.append(username)
        return usernameAvailabilityResult
    }
}
