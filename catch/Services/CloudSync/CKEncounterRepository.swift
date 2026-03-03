import CloudKit
import Observation
import os
import CatchCore

@Observable
@MainActor
final class CKEncounterRepository: EncounterRepository {
    private let container = CKContainer(identifier: "iCloud.com.catch.catch")
    private let logger = Logger(subsystem: "com.graysonmartin.catch", category: "CKEncounterRepository")

    private var database: CKDatabase {
        container.publicCloudDatabase
    }

    func save(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String {
        let recordName = payload.recordName ?? "\(ownerID)_enc_\(UUID().uuidString)"
        let recordID = CKRecord.ID(recordName: recordName)

        let existing: CKRecord?
        if payload.recordName != nil {
            do {
                existing = try await database.record(for: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                throw CloudSyncError.recordNotFound
            }
        } else {
            existing = nil
        }

        let record = EncounterRecordMapper.record(from: payload, ownerID: ownerID, existingRecord: existing, recordID: recordID)

        let assets = try CloudKitAssetManager.writePhotoAssets(payload.photos)
        defer { CloudKitAssetManager.cleanupTempFiles(assets) }
        record["photos"] = assets.isEmpty ? nil : assets

        let saved = try await database.save(record)
        return saved.recordID.recordName
    }

    func delete(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)
    }

    func fetchAll(ownerID: String) async throws -> [CloudEncounter] {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let query = CKQuery(recordType: EncounterRecordMapper.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        var allRecords: [CKRecord] = []

        let (firstResults, firstCursor) = try await database.records(matching: query, resultsLimit: 200)
        allRecords.append(contentsOf: extractRecords(from: firstResults))

        var cursor = firstCursor
        while let activeCursor = cursor {
            let (pageResults, nextCursor) = try await database.records(
                continuingMatchFrom: activeCursor,
                resultsLimit: 200
            )
            allRecords.append(contentsOf: extractRecords(from: pageResults))
            cursor = nextCursor
        }

        let photoSets = await CloudKitAssetManager.loadAllPhotos(from: allRecords)

        var encounters: [CloudEncounter] = []
        for (index, record) in allRecords.enumerated() {
            if let encounter = EncounterRecordMapper.cloudEncounter(from: record, photos: photoSets[index]) {
                encounters.append(encounter)
            } else {
                logger.warning("skipped encounter record \(record.recordID.recordName) — mapper returned nil")
            }
        }
        return encounters
    }

    // MARK: - Private

    private func extractRecords(from results: [(CKRecord.ID, Result<CKRecord, Error>)]) -> [CKRecord] {
        results.compactMap { recordID, result in
            switch result {
            case .success(let record):
                return record
            case .failure(let error):
                logger.error("failed to fetch encounter record \(recordID.recordName): \(error.localizedDescription)")
                return nil
            }
        }
    }
}
