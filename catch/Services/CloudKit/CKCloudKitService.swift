import CloudKit

@MainActor
final class CKCloudKitService: CloudKitService {
    private static let containerID = "iCloud.com.catch.catch"
    private static let recordType = "UserProfile"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - CloudKitService

    func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String
    ) async throws -> String {
        let recordID = CKRecord.ID(recordName: appleUserID)

        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: Self.recordType, recordID: recordID)
        }

        record["appleUserID"] = appleUserID
        record["displayName"] = displayName
        record["bio"] = bio

        let saved = try await database.save(record)
        return saved.recordID.recordName
    }

    func fetchUserProfile(appleUserID: String) async throws -> CloudUserProfile? {
        let recordID = CKRecord.ID(recordName: appleUserID)

        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }

        guard let appleID = record["appleUserID"] as? String,
              let displayName = record["displayName"] as? String,
              let bio = record["bio"] as? String else {
            return nil
        }

        return CloudUserProfile(
            recordName: record.recordID.recordName,
            appleUserID: appleID,
            displayName: displayName,
            bio: bio
        )
    }

    func deleteUserProfile(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)
    }
}
