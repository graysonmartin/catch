import Foundation

@MainActor
final class MockCloudKitService: CloudKitService {
    var savedProfiles: [(appleUserID: String, displayName: String, bio: String)] = []
    var fetchedAppleUserIDs: [String] = []
    var deletedRecordNames: [String] = []

    var saveResult: Result<String, any Error> = .success("mock-record-name")
    var fetchResult: CloudUserProfile?
    var deleteError: (any Error)?

    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String
    ) async throws -> String {
        savedProfiles.append((appleUserID, displayName, bio))
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
}
