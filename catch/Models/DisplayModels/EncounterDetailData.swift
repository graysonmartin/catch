import Foundation
import CatchCore

struct EncounterDetailData: Identifiable {
    let id: String
    let catName: String
    let catPhotoData: Data?
    let catPhotoUrl: String?
    let breed: String
    let isFirstEncounter: Bool
    let isUnnamed: Bool
    let isOwned: Bool
    let date: Date
    let locationName: String
    let notes: String
    let photos: [Data]
    let photoUrls: [String]
    let posterUserID: String?
    let posterDisplayName: String?
    let posterUsername: String?
    let posterAvatarURL: String?

    // MARK: - Local init

    init(local encounter: Encounter, isFirstEncounter: Bool) {
        let cat = Self.catFields(from: encounter.cat)
        self.id = encounter.id.uuidString
        self.catName = cat.name
        self.catPhotoData = nil
        self.catPhotoUrl = cat.photoUrl
        self.breed = cat.breed
        self.isFirstEncounter = isFirstEncounter
        self.isUnnamed = cat.isUnnamed
        self.isOwned = cat.isOwned
        self.date = encounter.date
        self.locationName = encounter.location.name
        self.notes = encounter.notes
        self.photos = []
        self.photoUrls = encounter.photoUrls.isEmpty ? (encounter.cat?.photoUrls ?? []) : encounter.photoUrls
        self.posterUserID = nil
        self.posterDisplayName = nil
        self.posterUsername = nil
        self.posterAvatarURL = nil
    }

    // MARK: - Supabase init (for notification deep links)

    init(supabase encounter: SupabaseEncounter, cat: Cat?) {
        let catInfo = Self.catFields(from: cat)
        self.id = encounter.id.uuidString
        self.catName = catInfo.name
        self.catPhotoData = nil
        self.catPhotoUrl = catInfo.photoUrl
        self.breed = catInfo.breed
        self.isFirstEncounter = false
        self.isUnnamed = catInfo.isUnnamed
        self.isOwned = catInfo.isOwned
        self.date = encounter.date
        self.locationName = encounter.locationName ?? ""
        self.notes = encounter.notes ?? ""
        self.photos = []
        self.photoUrls = encounter.photoUrls
        self.posterUserID = nil
        self.posterDisplayName = nil
        self.posterUsername = nil
        self.posterAvatarURL = nil
    }

    // MARK: - Shared Cat Fields

    private static func catFields(from cat: Cat?) -> (name: String, photoUrl: String?, breed: String, isUnnamed: Bool, isOwned: Bool) {
        (
            name: cat?.displayName ?? CatchStrings.Feed.unknownCat,
            photoUrl: cat?.photoUrls.first,
            breed: cat?.breed ?? "",
            isUnnamed: cat?.isUnnamed ?? false,
            isOwned: cat?.isOwned ?? false
        )
    }

    // MARK: - Remote CloudKit init

    init(remote encounter: CloudEncounter, cat: CloudCat?, isFirstEncounter: Bool, owner: CloudUserProfile? = nil) {
        self.id = encounter.recordName
        self.catName = cat?.displayName ?? CatchStrings.Social.unknownCat
        self.catPhotoData = cat?.photos.first
        self.catPhotoUrl = cat?.photoUrls.first
        self.breed = cat?.breed ?? ""
        self.isFirstEncounter = isFirstEncounter
        self.isUnnamed = cat?.isUnnamed ?? false
        self.isOwned = cat?.isOwned ?? false
        self.date = encounter.date
        self.locationName = encounter.locationName
        self.notes = encounter.notes
        self.photos = encounter.photos.isEmpty ? (cat?.photos ?? []) : encounter.photos
        self.photoUrls = encounter.photoUrls.isEmpty ? (cat?.photoUrls ?? []) : encounter.photoUrls
        self.posterUserID = owner?.appleUserID
        self.posterDisplayName = owner?.displayName
        self.posterUsername = owner?.username
        self.posterAvatarURL = owner?.avatarURL
    }
}
