import CloudKit

enum EncounterRecordMapper {
    static let recordType = "Encounter"

    static func record(
        from payload: EncounterSyncPayload,
        ownerID: String,
        existingRecord: CKRecord?,
        recordID: CKRecord.ID
    ) -> CKRecord {
        let record = existingRecord ?? CKRecord(recordType: recordType, recordID: recordID)

        record["ownerID"] = ownerID
        record["catRecordName"] = payload.catRecordName
        record["date"] = payload.date
        record["locationName"] = payload.locationName
        record["locationLatitude"] = payload.locationLatitude.map { $0 as CKRecordValue }
        record["locationLongitude"] = payload.locationLongitude.map { $0 as CKRecordValue }
        record["notes"] = payload.notes

        return record
    }

    static func cloudEncounter(from record: CKRecord, photos: [Data]) -> CloudEncounter? {
        guard let ownerID = record["ownerID"] as? String,
              let catRecordName = record["catRecordName"] as? String,
              let date = record["date"] as? Date else {
            return nil
        }

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
