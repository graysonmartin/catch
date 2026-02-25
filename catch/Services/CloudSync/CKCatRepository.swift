import CloudKit
import Observation

@Observable
@MainActor
final class CKCatRepository: CatRepository {
    private static let containerID = "iCloud.com.catch.catch"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    func save(_ payload: CatSyncPayload, ownerID: String) async throws -> String {
        let recordName = payload.recordName ?? "\(ownerID)_cat_\(UUID().uuidString)"
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

        let record = CatRecordMapper.record(from: payload, ownerID: ownerID, existingRecord: existing, recordID: recordID)

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

    func fetchAll(ownerID: String) async throws -> [CloudCat] {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let query = CKQuery(recordType: CatRecordMapper.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        return await results.asyncCompactMap { _, result -> CloudCat? in
            guard case .success(let record) = result else { return nil }
            let photos = await CloudKitAssetManager.loadPhotoData(from: record["photos"] as? [CKAsset])
            return CatRecordMapper.cloudCat(from: record, photos: photos)
        }
    }
}
