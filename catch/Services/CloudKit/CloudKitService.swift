import Foundation

@MainActor
protocol CloudKitService: Sendable {
    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String
    ) async throws -> String

    func fetchUserProfile(
        appleUserID: String
    ) async throws -> CloudUserProfile?

    func deleteUserProfile(
        recordName: String
    ) async throws
}

struct CloudUserProfile: Sendable {
    let recordName: String
    let appleUserID: String
    let displayName: String
    let bio: String
}
