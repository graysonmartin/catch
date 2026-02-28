import Foundation
@testable import CatchCore

@MainActor
final class MockCloudKitService: CloudKitService {
    var savedProfiles: [(appleUserID: String, displayName: String, bio: String, username: String?, isPrivate: Bool)] = []
    var fetchedAppleUserIDs: [String] = []
    var deletedRecordNames: [String] = []

    var saveResult: Result<String, any Error> = .success("mock-record-name")
    var fetchResult: CloudUserProfile?
    var deleteError: (any Error)?
    var searchUsersResult: [CloudUserProfile] = []
    private(set) var searchUsersCalls: [String] = []
    var fetchUserProfilesResult: [CloudUserProfile] = []
    private(set) var fetchUserProfilesCalls: [[String]] = []
    var usernameAvailabilityResult: Bool = true
    private(set) var usernameAvailabilityCalls: [String] = []

    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String?,
        isPrivate: Bool
    ) async throws -> String {
        savedProfiles.append((appleUserID, displayName, bio, username, isPrivate))
        return try saveResult.get()
    }

    func fetchUserProfile(appleUserID: String) async throws -> CloudUserProfile? {
        fetchedAppleUserIDs.append(appleUserID)
        return fetchResult
    }

    func deleteUserProfile(recordName: String) async throws {
        deletedRecordNames.append(recordName)
        if let error = deleteError { throw error }
    }

    func searchUsers(query: String) async throws -> [CloudUserProfile] {
        searchUsersCalls.append(query)
        return searchUsersResult
    }

    func fetchUserProfiles(appleUserIDs: [String]) async throws -> [CloudUserProfile] {
        fetchUserProfilesCalls.append(appleUserIDs)
        return fetchUserProfilesResult.filter { appleUserIDs.contains($0.appleUserID) }
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        usernameAvailabilityCalls.append(username)
        return usernameAvailabilityResult
    }
}
