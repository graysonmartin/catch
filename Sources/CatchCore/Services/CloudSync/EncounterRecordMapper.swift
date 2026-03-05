import CloudKit

public enum EncounterRecordMapper {
    public static let recordType = "Encounter"

    /// The CKReference field name for the cat parent relationship.
    public static let catReferenceKey = "catRef"

    public static func record(
        from payload: EncounterSyncPayload,
        ownerID: String,
        existingRecord: CKRecord?,
        recordID: CKRecord.ID
    ) -> CKRecord {
        let record = existingRecord ?? CKRecord(recordType: recordType, recordID: recordID)

        record["ownerID"] = ownerID
        // Keep string FK for backwards compatibility during transition
        record["catRecordName"] = payload.catRecordName
        record["date"] = payload.date
        record["locationName"] = payload.locationName
        record["locationLatitude"] = payload.locationLatitude.map { $0 as CKRecordValue }
        record["locationLongitude"] = payload.locationLongitude.map { $0 as CKRecordValue }
        record["notes"] = payload.notes

        // Write CKReference for cascade delete support
        let catRecordID = CKRecord.ID(recordName: payload.catRecordName)
        record[catReferenceKey] = CKRecord.Reference(recordID: catRecordID, action: .deleteSelf)

        return record
    }

    public static func cloudEncounter(from record: CKRecord, photos: [Data]) -> CloudEncounter? {
        // Prefer reference-based cat record name, fall back to string FK
        let catRecordName: String? = resolveCatRecordName(from: record)

        guard let ownerID = record["ownerID"] as? String,
              let catRecordName,
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

    /// Returns `true` if the record already has a `catRef` CKReference field populated.
    public static func hasReference(_ record: CKRecord) -> Bool {
        record[catReferenceKey] as? CKRecord.Reference != nil
    }

    /// Backfills the CKReference from the existing string FK field.
    /// Returns the mutated record ready to be saved, or `nil` if the record already has a reference
    /// or is missing the string FK.
    public static func backfillReference(on record: CKRecord) -> CKRecord? {
        guard !hasReference(record),
              let catRecordName = record["catRecordName"] as? String,
              !catRecordName.isEmpty else {
            return nil
        }

        let catRecordID = CKRecord.ID(recordName: catRecordName)
        record[catReferenceKey] = CKRecord.Reference(recordID: catRecordID, action: .deleteSelf)
        return record
    }

    // MARK: - Private

    /// Resolves cat record name preferring the CKReference, falling back to the string field.
    private static func resolveCatRecordName(from record: CKRecord) -> String? {
        if let ref = record[catReferenceKey] as? CKRecord.Reference {
            return ref.recordID.recordName
        }
        return record["catRecordName"] as? String
    }
}
