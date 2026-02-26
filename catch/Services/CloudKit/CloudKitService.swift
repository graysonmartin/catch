import Foundation

@MainActor
protocol CloudKitService: Sendable {
    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String?,
        isPrivate: Bool
    ) async throws -> String

    func fetchUserProfile(
        appleUserID: String
    ) async throws -> CloudUserProfile?

    func deleteUserProfile(
        recordName: String
    ) async throws

    func searchUsers(
        query: String
    ) async throws -> [CloudUserProfile]

    func checkUsernameAvailability(
        _ username: String
    ) async throws -> Bool
}

struct CloudUserProfile: Sendable {
    let recordName: String
    let appleUserID: String
    let displayName: String
    let bio: String
    var username: String?
    let isPrivate: Bool
}
