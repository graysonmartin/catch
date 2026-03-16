import Foundation
import CatchCore

@MainActor
@Observable
final class ProfileSyncService {
    private let profileRepository: any SupabaseProfileRepository

    init(profileRepository: any SupabaseProfileRepository) {
        self.profileRepository = profileRepository
    }

    func syncProfile(_ profile: UserProfile) async throws {
        guard let userID = profile.supabaseUserID else { return }

        let payload = SupabaseProfilePayload(
            displayName: profile.displayName,
            username: profile.username ?? "",
            bio: profile.bio,
            isPrivate: profile.isPrivate
        )

        // Try update first; if profile doesn't exist, create it
        let existing = try await profileRepository.fetchProfile(id: userID)
        if existing != nil {
            _ = try await profileRepository.updateProfile(id: userID, payload)
        } else {
            _ = try await profileRepository.createProfile(payload, id: userID)
        }
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
}
