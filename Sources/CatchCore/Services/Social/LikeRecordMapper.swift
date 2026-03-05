import CloudKit

public enum LikeRecordMapper {
    public static let recordType = "EncounterLike"

    /// The CKReference field name for the encounter parent relationship.
    public static let encounterReferenceKey = "encounterRef"

    public static func record(from like: EncounterLike) -> CKRecord {
        let recordID = CKRecord.ID(recordName: like.id)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        // Keep string FK for backwards compatibility during transition
        record["encounterRecordName"] = like.encounterRecordName
        record["userID"] = like.userID

        // Write CKReference for cascade delete support
        let encounterRecordID = CKRecord.ID(recordName: like.encounterRecordName)
        record[encounterReferenceKey] = CKRecord.Reference(recordID: encounterRecordID, action: .deleteSelf)

        return record
    }

    public static func like(from record: CKRecord) -> EncounterLike? {
        // Prefer reference-based encounter record name, fall back to string FK
        let encounterRecordName = resolveEncounterRecordName(from: record)

        guard let encounterRecordName,
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

    /// Returns `true` if the record already has an `encounterRef` CKReference field populated.
    public static func hasReference(_ record: CKRecord) -> Bool {
        record[encounterReferenceKey] as? CKRecord.Reference != nil
    }

    /// Backfills the CKReference from the existing string FK field.
    /// Returns the mutated record ready to be saved, or `nil` if already backfilled or missing the string FK.
    public static func backfillReference(on record: CKRecord) -> CKRecord? {
        guard !hasReference(record),
              let encounterRecordName = record["encounterRecordName"] as? String,
              !encounterRecordName.isEmpty else {
            return nil
        }

        let encounterRecordID = CKRecord.ID(recordName: encounterRecordName)
        record[encounterReferenceKey] = CKRecord.Reference(recordID: encounterRecordID, action: .deleteSelf)
        return record
    }

    // MARK: - Private

    private static func resolveEncounterRecordName(from record: CKRecord) -> String? {
        if let ref = record[encounterReferenceKey] as? CKRecord.Reference {
            return ref.recordID.recordName
        }
        return record["encounterRecordName"] as? String
    }
}
