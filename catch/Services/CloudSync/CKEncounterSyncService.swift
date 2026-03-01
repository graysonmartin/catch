import Foundation
import Observation
import os
import CatchCore

@Observable
@MainActor
final class CKEncounterSyncService: EncounterSyncService {
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

    func deleteEncounter(recordName: String) async throws {
        try await encounterRepository.delete(recordName: recordName)
    }
}
