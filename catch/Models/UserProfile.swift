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
    var supabaseUserID: String?
    var cloudKitRecordName: String?
    var isPrivate: Bool = false
    var visibilitySettings: VisibilitySettings = VisibilitySettings.default

    @Attribute(.externalStorage)
    var avatarData: Data?

    /// A profile is complete when the user has set a display name and a valid username.
    /// These are the minimum required fields before accessing the main app.
    var isProfileComplete: Bool {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedDisplayName.isEmpty else { return false }
        guard let username, !username.isEmpty else { return false }
        return UsernameValidator.validate(username) == .valid
    }

    init(
        displayName: String = "",
        bio: String = "",
        username: String? = nil,
        avatarData: Data? = nil,
        appleUserID: String? = nil,
        supabaseUserID: String? = nil,
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
        self.supabaseUserID = supabaseUserID
        self.cloudKitRecordName = cloudKitRecordName
        self.isPrivate = isPrivate
        self.visibilitySettings = visibilitySettings
    }
}
