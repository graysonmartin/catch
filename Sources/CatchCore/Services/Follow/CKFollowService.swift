import CloudKit
import Observation

@Observable
@MainActor
public final class CKFollowService: FollowService {
    public private(set) var followers: [Follow] = []
    public private(set) var following: [Follow] = []
    public private(set) var outgoingPending: [Follow] = []
    public private(set) var pendingRequests: [Follow] = []
    public private(set) var isLoading = false
    public private(set) var hasMoreFollowers = false
    public private(set) var hasMoreFollowing = false

    private static let containerID = "iCloud.com.catch.catch"
    private static let recordType = "Follow"

    private var followersCursor: CKQueryOperation.Cursor?
    private var followingCursor: CKQueryOperation.Cursor?

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    public init() {}

    // MARK: - FollowService

    public func follow(targetID: String, by userID: String, isTargetPrivate: Bool) async throws {
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

    public func unfollow(targetID: String, by userID: String) async throws {
        guard let match = following.first(where: { $0.followeeID == targetID }) else {
            throw FollowServiceError.followNotFound
        }
        let recordID = CKRecord.ID(recordName: match.id)
        try await database.deleteRecord(withID: recordID)
        following.removeAll { $0.id == match.id }
    }

    public func approveRequest(_ follow: Follow) async throws {
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

    public func declineRequest(_ follow: Follow) async throws {
        let recordID = CKRecord.ID(recordName: follow.id)
        try await database.deleteRecord(withID: recordID)
        pendingRequests.removeAll { $0.id == follow.id }
    }

    public func removeFollower(_ follow: Follow) async throws {
        let recordID = CKRecord.ID(recordName: follow.id)
        try await database.deleteRecord(withID: recordID)
        followers.removeAll { $0.id == follow.id }
    }

    public func refresh(for userID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        async let activeFollowers = paginatedQuery(
            field: "followeeID", value: userID, status: .active,
            limit: PaginationConstants.defaultPageSize
        )
        async let activeFollowing = paginatedQuery(
            field: "followerID", value: userID, status: .active,
            limit: PaginationConstants.defaultPageSize
        )
        async let pendingIncoming = query(field: "followeeID", value: userID, status: .pending)
        async let pendingOutgoing = query(field: "followerID", value: userID, status: .pending)

        let (fResult, gResult, pi, po) = try await (activeFollowers, activeFollowing, pendingIncoming, pendingOutgoing)
        followers = fResult.items
        followersCursor = fResult.cursor
        hasMoreFollowers = fResult.cursor != nil
        following = gResult.items
        followingCursor = gResult.cursor
        hasMoreFollowing = gResult.cursor != nil
        pendingRequests = pi
        outgoingPending = po
    }

    public func loadMoreFollowers(for userID: String) async throws {
        guard let cursor = followersCursor else { return }

        let (pageResults, nextCursor) = try await database.records(
            continuingMatchFrom: cursor,
            resultsLimit: PaginationConstants.defaultPageSize
        )
        let newFollows = pageResults.compactMap { _, result -> Follow? in
            guard case .success(let record) = result else { return nil }
            return Self.follow(from: record)
        }
        followers.append(contentsOf: newFollows)
        followersCursor = nextCursor
        hasMoreFollowers = nextCursor != nil
    }

    public func loadMoreFollowing(for userID: String) async throws {
        guard let cursor = followingCursor else { return }

        let (pageResults, nextCursor) = try await database.records(
            continuingMatchFrom: cursor,
            resultsLimit: PaginationConstants.defaultPageSize
        )
        let newFollows = pageResults.compactMap { _, result -> Follow? in
            guard case .success(let record) = result else { return nil }
            return Self.follow(from: record)
        }
        following.append(contentsOf: newFollows)
        followingCursor = nextCursor
        hasMoreFollowing = nextCursor != nil
    }

    public func fetchFollowers(for userID: String) async throws -> [Follow] {
        try await query(field: "followeeID", value: userID, status: .active)
    }

    public func fetchFollowing(for userID: String) async throws -> [Follow] {
        try await query(field: "followerID", value: userID, status: .active)
    }

    public func fetchFollowCounts(for userID: String) async throws -> (followers: Int, following: Int) {
        async let followerCount = countRecords(field: "followeeID", value: userID)
        async let followingCount = countRecords(field: "followerID", value: userID)
        return try await (followers: followerCount, following: followingCount)
    }

    public func isFollowing(_ targetID: String) -> Bool {
        following.contains { $0.followeeID == targetID }
    }

    public func pendingRequestTo(_ targetID: String) -> Follow? {
        outgoingPending.first { $0.followeeID == targetID }
    }

    // MARK: - Private

    private func countRecords(field: String, value: String) async throws -> Int {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", field, value),
            NSPredicate(format: "status == %@", FollowStatus.active.rawValue)
        ])
        let ckQuery = CKQuery(recordType: Self.recordType, predicate: predicate)
        let (results, _) = try await database.records(matching: ckQuery, resultsLimit: 200)
        return results.count
    }

    private struct PaginatedFollowResult {
        let items: [Follow]
        let cursor: CKQueryOperation.Cursor?
    }

    private func paginatedQuery(
        field: String,
        value: String,
        status: FollowStatus,
        limit: Int
    ) async throws -> PaginatedFollowResult {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", field, value),
            NSPredicate(format: "status == %@", status.rawValue)
        ])
        let ckQuery = CKQuery(recordType: Self.recordType, predicate: predicate)
        ckQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (results, cursor) = try await database.records(matching: ckQuery, resultsLimit: limit)
        let follows = results.compactMap { _, result -> Follow? in
            guard case .success(let record) = result else { return nil }
            return Self.follow(from: record)
        }
        return PaginatedFollowResult(items: follows, cursor: cursor)
    }

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

    // MARK: - Debug Seeding

    #if DEBUG
    public func seedFakeFollows(currentUserID: String) {
        guard following.isEmpty && followers.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        following = [
            Follow(
                id: "\(currentUserID)_fake-tuong",
                followerID: currentUserID,
                followeeID: "fake-tuong",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -20, to: now)!
            ),
            Follow(
                id: "\(currentUserID)_fake-sophi",
                followerID: currentUserID,
                followeeID: "fake-sophi",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -10, to: now)!
            ),
            Follow(
                id: "\(currentUserID)_fake-shiv",
                followerID: currentUserID,
                followeeID: "fake-shiv",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -5, to: now)!
            ),
            Follow(
                id: "\(currentUserID)_fake-mark",
                followerID: currentUserID,
                followeeID: "fake-mark",
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now)!
            )
        ]

        followers = [
            Follow(
                id: "fake-tuong_\(currentUserID)",
                followerID: "fake-tuong",
                followeeID: currentUserID,
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -18, to: now)!
            ),
            Follow(
                id: "fake-tatum_\(currentUserID)",
                followerID: "fake-tatum",
                followeeID: currentUserID,
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -7, to: now)!
            ),
            Follow(
                id: "fake-mark_\(currentUserID)",
                followerID: "fake-mark",
                followeeID: currentUserID,
                status: .active,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now)!
            )
        ]

        pendingRequests = [
            Follow(
                id: "fake-jorge_\(currentUserID)",
                followerID: "fake-jorge",
                followeeID: currentUserID,
                status: .pending,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!
            )
        ]
    }
    #endif
}
