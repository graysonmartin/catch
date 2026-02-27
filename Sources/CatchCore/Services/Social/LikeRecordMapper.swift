import CloudKit

public enum LikeRecordMapper {
    public static let recordType = "EncounterLike"

    public static func record(from like: EncounterLike) -> CKRecord {
        let recordID = CKRecord.ID(recordName: like.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["encounterRecordName"] = like.encounterRecordName
        record["userID"] = like.userID
        return record
    }

    public static func like(from record: CKRecord) -> EncounterLike? {
        guard let encounterRecordName = record["encounterRecordName"] as? String,
              let userID = record["userID"] as? String else {
            return nil
        }
        return EncounterLike(
            id: record.recordID.recordName,
            encounterRecordName: encounterRecordName,
            userID: userID,
            createdAt: record.creationDate ?? Date()
        )
    }
}
