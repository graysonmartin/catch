import Foundation
import Observation
import os
import CatchCore

@Observable
@MainActor
final class DefaultCatSyncService: CatSyncService {
    private(set) var isSyncing = false

    private let catRepository: any CatRepository
    private let encounterRepository: any EncounterRepository
    private let getUserID: () -> String?
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "CatSync")

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

    func syncNewCat(_ cat: Cat, firstEncounter: Encounter) async throws {
        guard let userID = getUserID() else {
            throw CloudSyncError.notSignedIn
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

        do {
            let encRecordName = try await encounterRepository.save(encPayload, ownerID: userID)
            firstEncounter.cloudKitRecordName = encRecordName
        } catch {
            // Encounter save failed — rollback the cat record
            do {
                try await catRepository.delete(recordName: catRecordName)
            } catch let rollbackError {
                logger.error("rollback of cat record \(catRecordName) failed: \(rollbackError.localizedDescription)")
            }
            cat.cloudKitRecordName = nil
            throw error
        }
    }

    // MARK: - Sync Cat Update

    func syncCatUpdate(_ cat: Cat) async throws {
        guard let userID = getUserID() else {
            throw CloudSyncError.notSignedIn
        }
        guard cat.cloudKitRecordName != nil else {
            throw CloudSyncError.recordNotFound
        }

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

        _ = try await catRepository.save(payload, ownerID: userID)
    }

    // MARK: - Delete

    func deleteCat(recordName: String) async throws {
        try await catRepository.delete(recordName: recordName)
    }
}
