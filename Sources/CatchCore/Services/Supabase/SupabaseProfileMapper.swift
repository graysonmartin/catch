import Foundation

public enum SupabaseProfileMapper {
    public static func toCloudUserProfile(_ profile: SupabaseProfile) -> CloudUserProfile {
        CloudUserProfile(
            recordName: profile.id.uuidString.lowercased(),
            appleUserID: profile.id.uuidString.lowercased(),
            displayName: profile.displayName,
            bio: profile.bio,
            username: profile.username,
            isPrivate: profile.isPrivate,
            avatarData: nil,
            avatarURL: profile.avatarUrl
        )
    }
}
