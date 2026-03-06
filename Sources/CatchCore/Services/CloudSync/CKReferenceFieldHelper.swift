import CloudKit

/// Shared helper for resolving record names from CKReference fields with string FK fallback.
enum CKReferenceFieldHelper {

    /// Resolves a record name by preferring the CKReference field, falling back to the string FK.
    static func resolve(from record: CKRecord, referenceKey: String, stringFKKey: String) -> String? {
        if let ref = record[referenceKey] as? CKRecord.Reference {
            return ref.recordID.recordName
        }
        return record[stringFKKey] as? String
    }
}
