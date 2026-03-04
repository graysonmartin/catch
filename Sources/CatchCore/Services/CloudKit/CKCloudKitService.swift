import CloudKit

@MainActor
public final class CKCloudKitService: CloudKitService {
    private static let containerID = "iCloud.com.catch.catch"
    private static let recordType = "UserProfile"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    public init() {}

    // MARK: - CloudKitService

    public func saveUserProfile(
        appleUserID: String,
        displayName: String,
        bio: String,
        username: String?,
        isPrivate: Bool
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
        record["username"] = username
        record["isPrivate"] = isPrivate ? 1 : 0

        let saved = try await database.save(record)
        return saved.recordID.recordName
    }

    public func fetchUserProfile(appleUserID: String) async throws -> CloudUserProfile? {
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

        let isPrivate = (record["isPrivate"] as? Int ?? 0) == 1
        let username = record["username"] as? String

        return CloudUserProfile(
            recordName: record.recordID.recordName,
            appleUserID: appleID,
            displayName: displayName,
            bio: bio,
            username: username,
            isPrivate: isPrivate
        )
    }

    public func deleteUserProfile(recordName: String) async throws {
        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)
    }

    public func searchUsers(query: String) async throws -> [CloudUserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // CloudKit doesn't support OR predicates — run two queries and merge
        async let nameResults = fetchProfiles(
            predicate: NSPredicate(format: "displayName BEGINSWITH[cd] %@", trimmed)
        )
        async let usernameResults = fetchProfiles(
            predicate: NSPredicate(format: "username BEGINSWITH[cd] %@", trimmed.lowercased())
        )

        let combined = try await nameResults + usernameResults
        var seen = Set<String>()
        return combined.filter { seen.insert($0.recordName).inserted }
    }

    private func fetchProfiles(predicate: NSPredicate) async throws -> [CloudUserProfile] {
        let ckQuery = CKQuery(recordType: Self.recordType, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
        let (results, _) = try await database.records(matching: ckQuery, resultsLimit: 20)

        return results.compactMap { _, result in
            guard case .success(let record) = result,
                  let appleID = record["appleUserID"] as? String,
                  let displayName = record["displayName"] as? String,
                  let bio = record["bio"] as? String else {
                return nil
            }
            let isPrivate = (record["isPrivate"] as? Int ?? 0) == 1
            let username = record["username"] as? String
            return CloudUserProfile(
                recordName: record.recordID.recordName,
                appleUserID: appleID,
                displayName: displayName,
                bio: bio,
                username: username,
                isPrivate: isPrivate
            )
        }
    }

    public func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let predicate = NSPredicate(format: "username == %@", username.lowercased())
        let ckQuery = CKQuery(recordType: Self.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: ckQuery, resultsLimit: 1)
        return results.isEmpty
    }
}
