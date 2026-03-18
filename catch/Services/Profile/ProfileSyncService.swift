import Foundation
import CatchCore

enum AvatarChange {
    case noChange
    case removed
    case updated(Data)
}

@MainActor
@Observable
final class ProfileSyncService {

    private let profileRepository: any SupabaseProfileRepository
    private let assetService: any SupabaseAssetService

    init(profileRepository: any SupabaseProfileRepository, assetService: any SupabaseAssetService) {
        self.profileRepository = profileRepository
        self.assetService = assetService
    }

    @discardableResult
    func syncProfile(_ profile: UserProfile, avatarChange: AvatarChange = .noChange) async throws -> String? {
        guard let userID = profile.supabaseUserID else { return nil }

        var avatarUrl = profile.avatarUrl
        switch avatarChange {
        case .noChange:
            break
        case .removed:
            if let oldUrl = avatarUrl {
                await deleteOldAvatar(oldUrl: oldUrl, userID: userID)
            }
            avatarUrl = nil
        case .updated(let data):
            if let oldUrl = avatarUrl {
                await deleteOldAvatar(oldUrl: oldUrl, userID: userID)
            }
            let versionedName = "avatar_\(UUID().uuidString.prefix(8)).jpg"
            avatarUrl = try await assetService.uploadPhoto(
                data,
                bucket: .profilePhotos,
                ownerID: userID,
                fileName: versionedName
            )
        }

        let payload = SupabaseProfilePayload(
            displayName: profile.displayName,
            username: profile.username ?? "",
            bio: profile.bio,
            isPrivate: profile.isPrivate,
            avatarUrl: avatarUrl
        )

        // Try update first; if profile doesn't exist, create it
        let existing = try await profileRepository.fetchProfile(id: userID)
        if existing != nil {
            _ = try await profileRepository.updateProfile(id: userID, payload)
        } else {
            _ = try await profileRepository.createProfile(payload, id: userID)
        }
        return avatarUrl
    }

    func fetchProfile(userID: String) async throws -> CloudUserProfile? {
        guard let profile = try await profileRepository.fetchProfile(id: userID) else {
            return nil
        }
        return SupabaseProfileMapper.toCloudUserProfile(profile)
    }

    func deleteProfile(userID: String) async throws {
        // Profile deletion is handled by Supabase cascade or RLS
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        try await profileRepository.checkUsernameAvailability(username)
    }

    func searchUsers(query: String) async throws -> [CloudUserProfile] {
        let profiles = try await profileRepository.searchUsers(query: query)
        return profiles.map { SupabaseProfileMapper.toCloudUserProfile($0) }
    }

    // MARK: - Private

    private func deleteOldAvatar(oldUrl: String, userID: String) async {
        RemoteImageCache.shared.removeImage(for: oldUrl)
        guard let url = URL(string: oldUrl) else { return }
        let oldFileName = url.lastPathComponent
        try? await assetService.deletePhoto(
            bucket: .profilePhotos,
            path: "\(userID)/\(oldFileName)"
        )
    }
}
