import Foundation

/// Errors that can occur during the CloudKit to Supabase migration.
public enum MigrationError: LocalizedError, Equatable {
    case missingUserMapping(appleUserID: String)
    case missingCatMapping(cloudKitRecordName: String)
    case missingEncounterMapping(cloudKitRecordName: String)
    case mappingFileNotFound(path: String)
    case invalidMappingFile(reason: String)
    case photoDownloadFailed(url: String, reason: String)
    case photoUploadFailed(bucket: String, reason: String)
    case supabaseInsertFailed(table: String, reason: String)
    case verificationFailed(entity: String, expected: Int, actual: Int)

    public var errorDescription: String? {
        switch self {
        case .missingUserMapping(let id):
            return "No Supabase user mapping for Apple user ID: \(id)"
        case .missingCatMapping(let name):
            return "No Supabase cat mapping for CloudKit record: \(name)"
        case .missingEncounterMapping(let name):
            return "No Supabase encounter mapping for CloudKit record: \(name)"
        case .mappingFileNotFound(let path):
            return "User mapping file not found at: \(path)"
        case .invalidMappingFile(let reason):
            return "Invalid mapping file: \(reason)"
        case .photoDownloadFailed(let url, let reason):
            return "Failed to download photo from \(url): \(reason)"
        case .photoUploadFailed(let bucket, let reason):
            return "Failed to upload photo to \(bucket): \(reason)"
        case .supabaseInsertFailed(let table, let reason):
            return "Failed to insert into \(table): \(reason)"
        case .verificationFailed(let entity, let expected, let actual):
            return "Verification failed for \(entity): expected \(expected), got \(actual)"
        }
    }
}
