import Foundation
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
        id: UUID = UUID(),
        ownerID: UUID = UUID()
    ) -> Cat {
        Cat(id: id, name: name, breed: breed, ownerID: ownerID)
    }

    static func encounter(
        for cat: Cat,
        date: Date = Date(),
        location: Location = .empty,
        notes: String = "",
        photoUrls: [String] = [],
        id: UUID = UUID()
    ) -> Encounter {
        Encounter(
            id: id,
            date: date,
            location: location,
            notes: notes,
            catID: cat.id,
            ownerID: cat.ownerID,
            photoUrls: photoUrls,
            cat: cat
        )
    }

    @discardableResult
    static func userProfile(
        displayName: String = "test user",
        bio: String = "test bio",
        username: String? = nil,
        supabaseUserID: String? = nil,
        isPrivate: Bool = false,
        visibilitySettings: VisibilitySettings = .default
    ) -> UserProfile {
        UserProfile(
            displayName: displayName,
            bio: bio,
            username: username,
            supabaseUserID: supabaseUserID,
            isPrivate: isPrivate,
            visibilitySettings: visibilitySettings
        )
    }
}
