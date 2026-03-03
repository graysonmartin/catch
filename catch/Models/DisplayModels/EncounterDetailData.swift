import Foundation
import CatchCore

struct EncounterDetailData: Identifiable {
    let id: String
    let catName: String
    let catPhotoData: Data?
    let isFirstEncounter: Bool
    let isUnnamed: Bool
    let isOwned: Bool
    let date: Date
    let locationName: String
    let notes: String
    let photos: [Data]

    // MARK: - Local SwiftData init

    init(local encounter: Encounter, isFirstEncounter: Bool) {
        self.id = encounter.cloudKitRecordName ?? UUID().uuidString
        self.catName = encounter.cat?.displayName ?? CatchStrings.Feed.unknownCat
        self.catPhotoData = encounter.cat?.photos.first
        self.isFirstEncounter = isFirstEncounter
        self.isUnnamed = encounter.cat?.isUnnamed ?? false
        self.isOwned = encounter.cat?.isOwned ?? false
        self.date = encounter.date
        self.locationName = encounter.location.name
        self.notes = encounter.notes
        self.photos = encounter.photos.isEmpty ? (encounter.cat?.photos ?? []) : encounter.photos
    }

    // MARK: - Remote CloudKit init

    init(remote encounter: CloudEncounter, cat: CloudCat?, isFirstEncounter: Bool) {
        self.id = encounter.recordName
        self.catName = cat?.displayName ?? CatchStrings.Social.unknownCat
        self.catPhotoData = cat?.photos.first
        self.isFirstEncounter = isFirstEncounter
        self.isUnnamed = cat?.isUnnamed ?? false
        self.isOwned = cat?.isOwned ?? false
        self.date = encounter.date
        self.locationName = encounter.locationName
        self.notes = encounter.notes
        self.photos = encounter.photos.isEmpty ? (cat?.photos ?? []) : encounter.photos
    }
}
