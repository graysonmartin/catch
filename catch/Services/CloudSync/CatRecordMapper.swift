import CloudKit

enum CatRecordMapper {
    static let recordType = "Cat"

    static func record(
        from payload: CatSyncPayload,
        ownerID: String,
        existingRecord: CKRecord?,
        recordID: CKRecord.ID
    ) -> CKRecord {
        let record = existingRecord ?? CKRecord(recordType: recordType, recordID: recordID)

        record["ownerID"] = ownerID
        record["name"] = payload.name
        record["breed"] = payload.breed
        record["estimatedAge"] = payload.estimatedAge
        record["locationName"] = payload.locationName
        record["locationLatitude"] = payload.locationLatitude.map { $0 as CKRecordValue }
        record["locationLongitude"] = payload.locationLongitude.map { $0 as CKRecordValue }
        record["notes"] = payload.notes
        record["isOwned"] = payload.isOwned ? 1 : 0
        record["createdAt"] = payload.createdAt
        record["personalityLabels"] = payload.personalityLabels as CKRecordValue

        return record
    }

    static func cloudCat(from record: CKRecord, photos: [Data]) -> CloudCat? {
        guard let ownerID = record["ownerID"] as? String,
              let name = record["name"] as? String else {
            return nil
        }

        return CloudCat(
            recordName: record.recordID.recordName,
            ownerID: ownerID,
            name: name,
            breed: record["breed"] as? String ?? "",
            estimatedAge: record["estimatedAge"] as? String ?? "",
            locationName: record["locationName"] as? String ?? "",
            locationLatitude: record["locationLatitude"] as? Double,
            locationLongitude: record["locationLongitude"] as? Double,
            notes: record["notes"] as? String ?? "",
            isOwned: (record["isOwned"] as? Int ?? 0) == 1,
            createdAt: record["createdAt"] as? Date ?? record.creationDate ?? Date(),
            photos: photos,
            personalityLabels: record["personalityLabels"] as? [String] ?? []
        )
    }
}
