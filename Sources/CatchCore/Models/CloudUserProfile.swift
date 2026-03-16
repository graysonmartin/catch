import Foundation

public struct CloudUserProfile: Sendable {
    public let recordName: String
    public let appleUserID: String
    public let displayName: String
    public let bio: String
    public var username: String?
    public let isPrivate: Bool
    public let avatarData: Data?
    public let avatarURL: String?

    public init(
        recordName: String,
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String? = nil,
        isPrivate: Bool,
        avatarData: Data? = nil,
        avatarURL: String? = nil
    ) {
        self.recordName = recordName
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.bio = bio
        self.username = username
        self.isPrivate = isPrivate
        self.avatarData = avatarData
        self.avatarURL = avatarURL
    }
}
