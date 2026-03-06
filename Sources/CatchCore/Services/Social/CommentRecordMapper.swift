import CloudKit

public enum CommentRecordMapper {
    public static let recordType = "EncounterComment"

    /// The CKReference field name for the encounter parent relationship.
    public static let encounterReferenceKey = "encounterRef"

    public static func record(from comment: EncounterComment) -> CKRecord {
        let recordID = CKRecord.ID(recordName: comment.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        // Keep string FK for backwards compatibility during transition
        record["encounterRecordName"] = comment.encounterRecordName
        record["userID"] = comment.userID
        record["text"] = comment.text

        // Write CKReference for cascade delete support
        let encounterRecordID = CKRecord.ID(recordName: comment.encounterRecordName)
        record[encounterReferenceKey] = CKRecord.Reference(recordID: encounterRecordID, action: .deleteSelf)

        return record
    }

    public static func comment(from record: CKRecord) -> EncounterComment? {
        // Prefer reference-based encounter record name, fall back to string FK
        let encounterRecordName = resolveEncounterRecordName(from: record)

        guard let encounterRecordName,
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

    // MARK: - Private

    private static func resolveEncounterRecordName(from record: CKRecord) -> String? {
        CKReferenceFieldHelper.resolve(from: record, referenceKey: encounterReferenceKey, stringFKKey: "encounterRecordName")
    }
}
