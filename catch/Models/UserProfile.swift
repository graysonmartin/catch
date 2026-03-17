import Foundation
import CatchCore

struct UserProfile: Identifiable, Sendable {
    let id: UUID
    var displayName: String
    var bio: String
    var username: String?
    var createdAt: Date
    var supabaseUserID: String?
    var isPrivate: Bool
    var visibilitySettings: VisibilitySettings
    var avatarUrl: String?

    var isProfileComplete: Bool {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedDisplayName.isEmpty else { return false }
        guard let username, !username.isEmpty else { return false }
        return UsernameValidator.validate(username) == .valid
    }

    init(
        id: UUID = UUID(),
        displayName: String = "",
        bio: String = "",
        username: String? = nil,
        supabaseUserID: String? = nil,
        isPrivate: Bool = false,
        visibilitySettings: VisibilitySettings = .default,
        avatarUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.bio = bio
        self.username = username
        self.createdAt = createdAt
        self.supabaseUserID = supabaseUserID
        self.isPrivate = isPrivate
        self.visibilitySettings = visibilitySettings
        self.avatarUrl = avatarUrl
    }

    // MARK: - Supabase Mapping

    init(supabase profile: SupabaseProfile) {
        self.id = profile.id
        self.displayName = profile.displayName
        self.bio = profile.bio
        self.username = profile.username
        self.createdAt = profile.createdAt
        self.supabaseUserID = profile.id.uuidString
        self.isPrivate = profile.isPrivate
        self.visibilitySettings = VisibilitySettings(
            showCats: profile.showCats,
            showEncounters: profile.showEncounters
        )
        self.avatarUrl = profile.avatarUrl
    }
}
