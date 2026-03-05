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
            isPrivate: profile.isPrivate
        )
        profile.cloudKitRecordName = recordName
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
