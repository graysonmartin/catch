import Foundation

@MainActor
public protocol CloudKitService: Sendable {
    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String?,
        isPrivate: Bool,
        avatarData: Data?
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

public struct CloudUserProfile: Sendable {
    public let recordName: String
    public let appleUserID: String
    public let displayName: String
    public let bio: String
    public var username: String?
    public let isPrivate: Bool
    public let avatarData: Data?

    public init(
        recordName: String,
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String? = nil,
        isPrivate: Bool,
        avatarData: Data? = nil
    ) {
        self.recordName = recordName
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.bio = bio
        self.username = username
        self.isPrivate = isPrivate
        self.avatarData = avatarData
    }
}
