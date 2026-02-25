import Foundation
import Observation
import os

@Observable
@MainActor
final class CKCatSyncService: CatSyncService {
    private(set) var isSyncing = false

    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository
    private let getUserID: () -> String?
    private let logger = Logger(subsystem: "com.catch.catch", category: "CatSync")

    init(
        catRepository: any CatRepository,
        encounterRepository: any EncounterRepository,
        getUserID: @escaping () -> String?
    ) {
        self.catRepository = catRepository
        self.encounterRepository = encounterRepository
        self.getUserID = getUserID
    }

    // MARK: - Sync New Cat + First Encounter

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async {
        guard let userID = getUserID() else {
            logger.info("skipping cat sync — not signed in")
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        let catPayload = CatSyncPayload(
            recordName: nil,
            name: cat.name,
            breed: cat.breed,
            estimatedAge: cat.estimatedAge,
            locationName: cat.location.name,
            locationLatitude: cat.location.latitude,
            locationLongitude: cat.location.longitude,
            notes: cat.notes,
            isOwned: cat.isOwned,
            createdAt: cat.createdAt,
            photos: cat.photos
        )

        do {
            let catRecordName = try await catRepository.save(catPayload, ownerID: userID)
            cat.cloudKitRecordName = catRecordName

            let encPayload = EncounterSyncPayload(
                recordName: nil,
                catRecordName: catRecordName,
                date: firstEncounter.date,
                locationName: firstEncounter.location.name,
                locationLatitude: firstEncounter.location.latitude,
                locationLongitude: firstEncounter.location.longitude,
                notes: firstEncounter.notes,
                photos: firstEncounter.photos
            )

            let encRecordName = try await encounterRepository.save(encPayload, ownerID: userID)
            firstEncounter.cloudKitRecordName = encRecordName
        } catch {
            logger.error("cat sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Cat Update

    func syncCatUpdate(_ cat: Cat) async {
        guard let userID = getUserID() else { return }
        guard cat.cloudKitRecordName != nil else { return }

        isSyncing = true
        defer { isSyncing = false }

        let payload = CatSyncPayload(
            recordName: cat.cloudKitRecordName,
            name: cat.name,
            breed: cat.breed,
            estimatedAge: cat.estimatedAge,
            locationName: cat.location.name,
            locationLatitude: cat.location.latitude,
            locationLongitude: cat.location.longitude,
            notes: cat.notes,
            isOwned: cat.isOwned,
            createdAt: cat.createdAt,
            photos: cat.photos
        )

        do {
            _ = try await catRepository.save(payload, ownerID: userID)
        } catch {
            logger.error("cat update sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    func deleteCat(recordName: String) async throws {
        try await catRepository.delete(recordName: recordName)
    }
}
