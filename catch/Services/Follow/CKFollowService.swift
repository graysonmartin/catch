import CloudKit
import Observation

@Observable
@MainActor
final class CKFollowService: FollowService {
    private(set) var followers: [Follow] = []
    private(set) var following: [Follow] = []
    private(set) var outgoingPending: [Follow] = []
    private(set) var pendingRequests: [Follow] = []
    private(set) var isLoading = false

    private static let containerID = "iCloud.com.catch.catch"
    private static let recordType = "Follow"

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - FollowService

    func follow(targetID: String, by userID: String, isTargetPrivate: Bool) async throws {
        guard userID != targetID else { throw FollowServiceError.cannotFollowSelf }
        guard !isFollowing(targetID) else { throw FollowServiceError.alreadyFollowing }
        guard pendingRequestTo(targetID) == nil else { throw FollowServiceError.requestAlreadyPending }

        let status: FollowStatus = isTargetPrivate ? .pending : .active
        let recordID = CKRecord.ID(recordName: "\(userID)_\(targetID)")
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["followerID"] = userID
        record["followeeID"] = targetID
        record["status"] = status.rawValue

        let saved = try await database.save(record)
        let follow = Self.follow(from: saved)

        if follow.isActive {
            following.append(follow)
        } else {
            outgoingPending.append(follow)
        }
    }

    func unfollow(targetID: String, by userID: String) async throws {
        guard let match = following.first(where: { $0.followeeID == targetID }) else {
            throw FollowServiceError.followNotFound
        }
        let recordID = CKRecord.ID(recordName: match.id)
        try await database.deleteRecord(withID: recordID)
        following.removeAll { $0.id == match.id }
    }

    func approveRequest(_ follow: Follow) async throws {
        let recordID = CKRecord.ID(recordName: follow.id)
        let record = try await database.record(for: recordID)
        record["status"] = FollowStatus.active.rawValue
        try await database.save(record)

        pendingRequests.removeAll { $0.id == follow.id }
        let approved = Follow(
            id: follow.id,
            followerID: follow.followerID,
            followeeID: follow.followeeID,
            status: .active,
            createdAt: follow.createdAt
        )
        followers.append(approved)
    }

    func declineRequest(_ follow: Follow) async throws {
        let recordID = CKRecord.ID(recordName: follow.id)
        try await database.deleteRecord(withID: recordID)
        pendingRequests.removeAll { $0.id == follow.id }
    }

    func removeFollower(_ follow: Follow) async throws {
        let recordID = CKRecord.ID(recordName: follow.id)
        try await database.deleteRecord(withID: recordID)
        followers.removeAll { $0.id == follow.id }
    }

    func refresh(for userID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        async let activeFollowers = query(field: "followeeID", value: userID, status: .active)
        async let activeFollowing = query(field: "followerID", value: userID, status: .active)
        async let pendingIncoming = query(field: "followeeID", value: userID, status: .pending)
        async let pendingOutgoing = query(field: "followerID", value: userID, status: .pending)

        let (f, g, pi, po) = try await (activeFollowers, activeFollowing, pendingIncoming, pendingOutgoing)
        followers = f
        following = g
        pendingRequests = pi
        outgoingPending = po
    }

    func isFollowing(_ targetID: String) -> Bool {
        following.contains { $0.followeeID == targetID }
    }

    func pendingRequestTo(_ targetID: String) -> Follow? {
        outgoingPending.first { $0.followeeID == targetID }
    }

    // MARK: - Private

    private func query(field: String, value: String, status: FollowStatus) async throws -> [Follow] {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", field, value),
            NSPredicate(format: "status == %@", status.rawValue)
        ])
        let ckQuery = CKQuery(recordType: Self.recordType, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (results, _) = try await database.records(matching: ckQuery, resultsLimit: 200)
        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return Self.follow(from: record)
        }
    }

    private static func follow(from record: CKRecord) -> Follow {
        Follow(
            id: record.recordID.recordName,
            followerID: record["followerID"] as? String ?? "",
            followeeID: record["followeeID"] as? String ?? "",
            status: FollowStatus(rawValue: record["status"] as? String ?? "") ?? .pending,
            createdAt: record.creationDate ?? Date()
        )
    }
}
