import Foundation
import SwiftData

@Model
final class UserProfile {
    var displayName: String
    var bio: String
    var createdAt: Date

    @Attribute(.externalStorage)
    var avatarData: Data?

    init(
        displayName: String = "",
        bio: String = "",
        avatarData: Data? = nil
    ) {
        self.displayName = displayName
        self.bio = bio
        self.createdAt = Date()
        self.avatarData = avatarData
    }
}
