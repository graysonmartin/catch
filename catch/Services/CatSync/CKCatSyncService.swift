import CloudKit
import Observation

@Observable
@MainActor
final class CKCatSyncService: CatSyncService {
    private static let containerID = "iCloud.com.catch.catch"
    private static let catRecordType = "Cat"
    private static let encounterRecordType = "Encounter"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - Save Cat

    func saveCat(_ payload: CatSyncPayload, ownerID: String) async throws -> String {
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
            record = CKRecord(recordType: Self.catRecordType, recordID: recordID)
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

        let assets = try writePhotoAssets(payload.photos)
        defer { cleanupTempFiles(assets) }
        record["photos"] = assets.isEmpty ? nil : assets

        let saved = try await database.save(record)
        return saved.recordID.recordName
    }

    // MARK: - Save Encounter

    func saveEncounter(_ payload: EncounterSyncPayload, ownerID: String) async throws -> String {
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
            record = CKRecord(recordType: Self.encounterRecordType, recordID: recordID)
        }

        record["ownerID"] = ownerID
        record["catRecordName"] = payload.catRecordName
        record["date"] = payload.date
        record["locationName"] = payload.locationName
        record["locationLatitude"] = payload.locationLatitude.map { $0 as CKRecordValue }
        record["locationLongitude"] = payload.locationLongitude.map { $0 as CKRecordValue }
        record["notes"] = payload.notes

        let assets = try writePhotoAssets(payload.photos)
        defer { cleanupTempFiles(assets) }
        record["photos"] = assets.isEmpty ? nil : assets

        let saved = try await database.save(record)
        return saved.recordID.recordName
    }

    // MARK: - Delete

    func deleteCat(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)
    }

    func deleteEncounter(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)
    }

    // MARK: - Fetch

    func fetchCats(ownerID: String) async throws -> [CloudCat] {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let query = CKQuery(recordType: Self.catRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        return await results.asyncCompactMap { _, result -> CloudCat? in
            guard case .success(let record) = result else { return nil }
            return await self.cloudCat(from: record)
        }
    }

    func fetchEncounters(ownerID: String) async throws -> [CloudEncounter] {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let query = CKQuery(recordType: Self.encounterRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        return await results.asyncCompactMap { _, result -> CloudEncounter? in
            guard case .success(let record) = result else { return nil }
            return await self.cloudEncounter(from: record)
        }
    }

    // MARK: - Private

    private func cloudCat(from record: CKRecord) async -> CloudCat? {
        guard let ownerID = record["ownerID"] as? String,
              let name = record["name"] as? String else {
            return nil
        }

        let photos = await loadPhotoData(from: record["photos"] as? [CKAsset])

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

    private func cloudEncounter(from record: CKRecord) async -> CloudEncounter? {
        guard let ownerID = record["ownerID"] as? String,
              let catRecordName = record["catRecordName"] as? String,
              let date = record["date"] as? Date else {
            return nil
        }

        let photos = await loadPhotoData(from: record["photos"] as? [CKAsset])

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

    private nonisolated func writePhotoAssets(_ photos: [Data]) throws -> [CKAsset] {
        let tempDir = FileManager.default.temporaryDirectory
        return try photos.enumerated().map { index, data in
            let url = tempDir.appendingPathComponent("catsync_\(UUID().uuidString)_\(index).jpg")
            try data.write(to: url)
            return CKAsset(fileURL: url)
        }
    }

    private nonisolated func cleanupTempFiles(_ assets: [CKAsset]) {
        for asset in assets {
            if let url = asset.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private nonisolated func loadPhotoData(from assets: [CKAsset]?) async -> [Data] {
        guard let assets else { return [] }
        return assets.compactMap { asset in
            guard let url = asset.fileURL else { return nil }
            return try? Data(contentsOf: url)
        }
    }
}

// MARK: - Async Helpers

private extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var results: [T] = []
        for element in self {
            if let transformed = await transform(element) {
                results.append(transformed)
            }
        }
        return results
    }
}
