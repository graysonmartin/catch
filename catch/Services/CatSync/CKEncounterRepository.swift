import CloudKit
import Observation

@Observable
@MainActor
final class CKEncounterRepository: EncounterRepository {
    private static let containerID = "iCloud.com.catch.catch"
    private static let recordType = "Encounter"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - Save

    func save(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String {
        let recordName = payload.recordName ?? "\(ownerID)_enc_\(UUID().uuidString)"
        let recordID = CKRecord.ID(recordName: recordName)

        let record: CKRecord
        if payload.recordName != nil {
            do {
                record = try await database.record(for: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                throw CatSyncServiceError.recordNotFound
            }
        } else {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
        }

        record["ownerID"] = ownerID
        record["catRecordName"] = payload.catRecordName
        record["date"] = payload.date
        record["locationName"] = payload.locationName
        record["locationLatitude"] = payload.locationLatitude.map { $0 as CKRecordValue }
        record["locationLongitude"] = payload.locationLongitude.map { $0 as CKRecordValue }
        record["notes"] = payload.notes

        let assets = try CloudKitAssetManager.writePhotoAssets(payload.photos)
        defer { CloudKitAssetManager.cleanupTempFiles(assets) }
        record["photos"] = assets.isEmpty ? nil : assets

        let saved = try await database.save(record)
        return saved.recordID.recordName
    }

    // MARK: - Delete

    func delete(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)
    }

    // MARK: - Fetch

    func fetchAll(ownerID: String) async throws -> [CloudEncounter] {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        return await results.asyncCompactMap { _, result -> CloudEncounter? in
            guard case .success(let record) = result else { return nil }
            return await Self.cloudEncounter(from: record)
        }
    }

    // MARK: - Private

    private static func cloudEncounter(from record: CKRecord) async -> CloudEncounter? {
        guard let ownerID = record["ownerID"] as? String,
              let catRecordName = record["catRecordName"] as? String,
              let date = record["date"] as? Date else {
            return nil
        }

        let photos = await CloudKitAssetManager.loadPhotoData(from: record["photos"] as? [CKAsset])

        return CloudEncounter(
            recordName: record.recordID.recordName,
            ownerID: ownerID,
            catRecordName: catRecordName,
            date: date,
            locationName: record["locationName"] as? String ?? "",
            locationLatitude: record["locationLatitude"] as? Double,
            locationLongitude: record["locationLongitude"] as? Double,
            notes: record["notes"] as? String ?? "",
            photos: photos
        )
    }
}
