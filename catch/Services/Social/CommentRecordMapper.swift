import CloudKit

enum CommentRecordMapper {
    static let recordType = "EncounterComment"

    static func record(from comment: EncounterComment) -> CKRecord {
        let recordID = CKRecord.ID(recordName: comment.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["encounterRecordName"] = comment.encounterRecordName
        record["userID"] = comment.userID
        record["text"] = comment.text
        return record
    }

    static func comment(from record: CKRecord) -> EncounterComment? {
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
