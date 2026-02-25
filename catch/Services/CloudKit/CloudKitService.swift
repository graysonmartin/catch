import Foundation

@MainActor
protocol CloudKitService: Sendable {
    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String,
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
}

struct CloudUserProfile: Sendable {
    let recordName: String
    let appleUserID: String
    let displayName: String
    let bio: String
    let isPrivate: Bool
}
