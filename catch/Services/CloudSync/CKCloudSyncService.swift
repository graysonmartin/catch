import Foundation
import Observation
import os

@Observable
@MainActor
final class CKCloudSyncService: CloudSyncService {
    private(set) var isSyncing = false

    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository
    private let getUserID: () -> String?
    private let logger = Logger(subsystem: "com.catch.catch", category: "CloudSync")

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

    // MARK: - Sync New Encounter

    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async {
        guard let userID = getUserID() else { return }
        guard let catRecordName = cat.cloudKitRecordName else { return }

        isSyncing = true
        defer { isSyncing = false }

        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: catRecordName,
            date: encounter.date,
            locationName: encounter.location.name,
            locationLatitude: encounter.location.latitude,
            locationLongitude: encounter.location.longitude,
            notes: encounter.notes,
            photos: encounter.photos
        )

        do {
            let recordName = try await encounterRepository.save(payload, ownerID: userID)
            encounter.cloudKitRecordName = recordName
        } catch {
            logger.error("encounter sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Encounter Update

    func syncEncounterUpdate(_ encounter: Encounter) async {
        guard let userID = getUserID() else { return }
        guard let encRecordName = encounter.cloudKitRecordName,
              let catRecordName = encounter.cat?.cloudKitRecordName else { return }

        isSyncing = true
        defer { isSyncing = false }

        let payload = EncounterSyncPayload(
            recordName: encRecordName,
            catRecordName: catRecordName,
            date: encounter.date,
            locationName: encounter.location.name,
            locationLatitude: encounter.location.latitude,
            locationLongitude: encounter.location.longitude,
            notes: encounter.notes,
            photos: encounter.photos
        )

        do {
            _ = try await encounterRepository.save(payload, ownerID: userID)
        } catch {
            logger.error("encounter update sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    func deleteCat(recordName: String) async throws {
        try await catRepository.delete(recordName: recordName)
    }

    func deleteEncounter(recordName: String) async throws {
        try await encounterRepository.delete(recordName: recordName)
    }
}
