import Foundation
import CatchCore

struct ProfileDisplayData {
    let displayName: String
    let username: String?
    let bio: String
    let avatarData: Data?
    let isPrivate: Bool
    let createdAt: Date
    let catCount: Int
    let encounterCount: Int

    // MARK: - Local SwiftData init

    init(local profile: UserProfile, catCount: Int, encounterCount: Int) {
        self.displayName = profile.displayName
        self.username = profile.username
        self.bio = profile.bio
        self.avatarData = profile.avatarData
        self.isPrivate = profile.isPrivate
        self.createdAt = profile.createdAt
        self.catCount = catCount
        self.encounterCount = encounterCount
    }

    // MARK: - Remote CloudKit init

    init(remote data: UserBrowseData) {
        self.displayName = data.profile.displayName
        self.username = data.profile.username
        self.bio = data.profile.bio
        self.avatarData = nil
        self.isPrivate = data.profile.isPrivate
        self.createdAt = Date()
        self.catCount = data.cats.count
        self.encounterCount = data.encounters.count
    }
}
