import Foundation
import CatchCore

@MainActor
@Observable
final class ProfileSyncService {
    private let cloudKitService: CloudKitService

    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }

    func syncProfile(_ profile: UserProfile) async throws {
        guard let appleUserID = profile.appleUserID else { return }
        let recordName = try await cloudKitService.saveUserProfile(
            appleUserID: appleUserID,
            displayName: profile.displayName,
            bio: profile.bio,
            username: profile.username,
            isPrivate: profile.isPrivate,
            avatarData: profile.avatarData
        )
        profile.cloudKitRecordName = recordName
    }

    func restoreProfile(from cloudProfile: CloudUserProfile, to localProfile: UserProfile) {
        localProfile.displayName = cloudProfile.displayName
        localProfile.bio = cloudProfile.bio
        localProfile.username = cloudProfile.username
        localProfile.isPrivate = cloudProfile.isPrivate
        localProfile.avatarData = cloudProfile.avatarData
        localProfile.cloudKitRecordName = cloudProfile.recordName
    }

    func fetchProfile(appleUserID: String) async throws -> CloudUserProfile? {
        try await cloudKitService.fetchUserProfile(appleUserID: appleUserID)
    }

    func deleteProfile(recordName: String) async throws {
        try await cloudKitService.deleteUserProfile(recordName: recordName)
    }

    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        try await cloudKitService.checkUsernameAvailability(username)
    }
}
