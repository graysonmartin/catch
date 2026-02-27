import CloudKit

public enum CommentRecordMapper {
    public static let recordType = "EncounterComment"

    public static func record(from comment: EncounterComment) -> CKRecord {
        let recordID = CKRecord.ID(recordName: comment.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["encounterRecordName"] = comment.encounterRecordName
        record["userID"] = comment.userID
        record["text"] = comment.text
        return record
    }

    public static func comment(from record: CKRecord) -> EncounterComment? {
        guard let encounterRecordName = record["encounterRecordName"] as? String,
              let userID = record["userID"] as? String,
              let text = record["text"] as? String else {
            return nil
        }
        return EncounterComment(
            id: record.recordID.recordName,
            encounterRecordName: encounterRecordName,
            userID: userID,
            text: text,
            createdAt: record.creationDate ?? Date()
        )
    }
}
