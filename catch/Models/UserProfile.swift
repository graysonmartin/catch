import Foundation
import SwiftData

@Model
final class UserProfile {
    var displayName: String
    var bio: String
    var createdAt: Date
    var appleUserID: String?
    var cloudKitRecordName: String?
    var isPrivate: Bool = false

    @Attribute(.externalStorage)
    var avatarData: Data?

    init(
        displayName: String = "",
        bio: String = "",
        avatarData: Data? = nil,
        appleUserID: String? = nil,
        cloudKitRecordName: String? = nil,
        isPrivate: Bool = false
    ) {
        self.displayName = displayName
        self.bio = bio
        self.createdAt = Date()
        self.avatarData = avatarData
        self.appleUserID = appleUserID
        self.cloudKitRecordName = cloudKitRecordName
        self.isPrivate = isPrivate
    }
}
