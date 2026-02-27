import Foundation
import SwiftData
import CatchCore

extension Location {
    static func make(
        name: String = "Back Alley",
        latitude: Double? = 37.334722,
        longitude: Double? = -122.008889
    ) -> Location {
        Location(name: name, latitude: latitude, longitude: longitude)
    }
}

@MainActor
enum Fixtures {
    static func cat(
        name: String? = "Mr. Whiskers",
        breed: String? = nil,
        cloudKitRecordName: String? = nil,
        in context: ModelContext
    ) -> Cat {
        let cat = Cat(name: name, breed: breed)
        cat.cloudKitRecordName = cloudKitRecordName
        context.insert(cat)
        return cat
    }

    static func encounter(
        for cat: Cat,
        date: Date = Date(),
        location: Location = .empty,
        notes: String = "",
        photos: [Data] = [],
        cloudKitRecordName: String? = nil,
        in context: ModelContext
    ) -> Encounter {
        let encounter = Encounter(date: date, location: location, notes: notes, cat: cat, photos: photos)
        encounter.cloudKitRecordName = cloudKitRecordName
        context.insert(encounter)
        return encounter
    }

    @discardableResult
    static func userProfile(
        displayName: String = "test user",
        bio: String = "test bio",
        username: String? = nil,
        avatarData: Data? = nil,
        appleUserID: String? = nil,
        cloudKitRecordName: String? = nil,
        isPrivate: Bool = false,
        visibilitySettings: VisibilitySettings = .default,
        in context: ModelContext
    ) -> UserProfile {
        let profile = UserProfile(
            displayName: displayName,
            bio: bio,
            username: username,
            avatarData: avatarData,
            appleUserID: appleUserID,
            cloudKitRecordName: cloudKitRecordName,
            isPrivate: isPrivate,
            visibilitySettings: visibilitySettings
        )
        context.insert(profile)
        return profile
    }
}
