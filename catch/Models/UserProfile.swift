import Foundation
import SwiftData
import CatchCore

@Model
final class UserProfile {
    var displayName: String
    var bio: String
    var username: String?
    var createdAt: Date
    var appleUserID: String?
    var cloudKitRecordName: String?
    var isPrivate: Bool = false
    var visibilitySettings: VisibilitySettings = VisibilitySettings.default

    @Attribute(.externalStorage)
    var avatarData: Data?

    init(
        displayName: String = "",
        bio: String = "",
        username: String? = nil,
        avatarData: Data? = nil,
        appleUserID: String? = nil,
        cloudKitRecordName: String? = nil,
        isPrivate: Bool = false,
        visibilitySettings: VisibilitySettings = .default
    ) {
        self.displayName = displayName
        self.bio = bio
        self.username = username
        self.createdAt = Date()
        self.avatarData = avatarData
        self.appleUserID = appleUserID
        self.cloudKitRecordName = cloudKitRecordName
        self.isPrivate = isPrivate
        self.visibilitySettings = visibilitySettings
    }
}
