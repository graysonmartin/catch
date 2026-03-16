import Foundation
import Observation
import os
import CatchCore

@Observable
@MainActor
final class DefaultEncounterSyncService: EncounterSyncService {
    private(set) var isSyncing = false

    private let encounterRepository: any EncounterRepository
    private let getUserID: () -> String?
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "EncounterSync")

    init(
        encounterRepository: any EncounterRepository,
        getUserID: @escaping () -> String?
    ) {
        self.encounterRepository = encounterRepository
        self.getUserID = getUserID
    }

    // MARK: - Sync New Encounter

    func syncNewEncounter(_ encounter: Encounter, for cat: Cat) async throws {
        guard let userID = getUserID() else {
            throw CloudSyncError.notSignedIn
        }
        guard let catRecordName = cat.cloudKitRecordName else {
            throw CloudSyncError.recordNotFound
        }

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

        let recordName = try await encounterRepository.save(payload, ownerID: userID)
        encounter.cloudKitRecordName = recordName
    }

    // MARK: - Sync Encounter Update

    func syncEncounterUpdate(_ encounter: Encounter) async throws {
        guard let userID = getUserID() else {
            throw CloudSyncError.notSignedIn
        }
        guard let encRecordName = encounter.cloudKitRecordName,
              let catRecordName = encounter.cat?.cloudKitRecordName else {
            throw CloudSyncError.recordNotFound
        }

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

        _ = try await encounterRepository.save(payload, ownerID: userID)
    }

    // MARK: - Delete

    func deleteEncounter(recordName: String) async throws {
        try await encounterRepository.delete(recordName: recordName)
    }
}
