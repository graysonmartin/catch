import CloudKit
import Observation

@Observable
@MainActor
final class CKCatRepository: CatRepository {
    private static let containerID = "iCloud.com.catch.catch"
    private static let recordType = "Cat"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - Save

    func save(_ payload: CatSyncPayload, ownerID: String) async throws -> String {
        let recordName = payload.recordName ?? "\(ownerID)_cat_\(UUID().uuidString)"
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
        record["name"] = payload.name
        record["estimatedAge"] = payload.estimatedAge
        record["locationName"] = payload.locationName
        record["locationLatitude"] = payload.locationLatitude.map { $0 as CKRecordValue }
        record["locationLongitude"] = payload.locationLongitude.map { $0 as CKRecordValue }
        record["notes"] = payload.notes
        record["isOwned"] = payload.isOwned ? 1 : 0
        record["createdAt"] = payload.createdAt

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

    func fetchAll(ownerID: String) async throws -> [CloudCat] {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        return await results.asyncCompactMap { _, result -> CloudCat? in
            guard case .success(let record) = result else { return nil }
            return await Self.cloudCat(from: record)
        }
    }

    // MARK: - Private

    private static func cloudCat(from record: CKRecord) async -> CloudCat? {
        guard let ownerID = record["ownerID"] as? String,
              let name = record["name"] as? String else {
            return nil
        }

        let photos = await CloudKitAssetManager.loadPhotoData(from: record["photos"] as? [CKAsset])

        return CloudCat(
            recordName: record.recordID.recordName,
            ownerID: ownerID,
            name: name,
            estimatedAge: record["estimatedAge"] as? String ?? "",
            locationName: record["locationName"] as? String ?? "",
            locationLatitude: record["locationLatitude"] as? Double,
            locationLongitude: record["locationLongitude"] as? Double,
            notes: record["notes"] as? String ?? "",
            isOwned: (record["isOwned"] as? Int ?? 0) == 1,
            createdAt: record["createdAt"] as? Date ?? record.creationDate ?? Date(),
            photos: photos
        )
    }
}
