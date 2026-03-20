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

    // MARK: - Local init

    init(local encounter: Encounter, isFirstEncounter: Bool) {
        self.id = encounter.id.uuidString
        self.catName = encounter.cat?.displayName ?? CatchStrings.Feed.unknownCat
        self.catPhotoData = nil
        self.catPhotoUrl = encounter.cat?.photoUrls.first
        self.breed = encounter.cat?.breed ?? ""
        self.isFirstEncounter = isFirstEncounter
        self.isUnnamed = encounter.cat?.isUnnamed ?? false
        self.isOwned = encounter.cat?.isOwned ?? false
        self.date = encounter.date
        self.locationName = encounter.location.name
        self.notes = encounter.notes
        self.photos = []
        self.photoUrls = encounter.photoUrls.isEmpty ? (encounter.cat?.photoUrls ?? []) : encounter.photoUrls
    }

    // MARK: - Supabase init (for notification deep links)

    init(supabase encounter: SupabaseEncounter, cat: Cat?) {
        self.id = encounter.id.uuidString
        self.catName = cat?.displayName ?? CatchStrings.Feed.unknownCat
        self.catPhotoData = nil
        self.catPhotoUrl = cat?.photoUrls.first
        self.breed = cat?.breed ?? ""
        self.isFirstEncounter = false
        self.isUnnamed = cat?.isUnnamed ?? true
        self.isOwned = cat?.isOwned ?? false
        self.date = encounter.date
        self.locationName = encounter.locationName ?? ""
        self.notes = encounter.notes ?? ""
        self.photos = []
        self.photoUrls = encounter.photoUrls
    }

    // MARK: - Remote CloudKit init

    init(remote encounter: CloudEncounter, cat: CloudCat?, isFirstEncounter: Bool) {
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
    }
}
