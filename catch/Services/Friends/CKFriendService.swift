import CloudKit
import Observation

@Observable
@MainActor
final class CKFriendService: FriendService {
    private static let containerID = "iCloud.com.catch.catch"
    private static let requestRecordType = "FriendRequest"
    private static let friendshipRecordType = "Friendship"

    private(set) var incomingRequests: [FriendRequest] = []
    private(set) var outgoingRequests: [FriendRequest] = []
    private(set) var friends: [Friendship] = []
    private(set) var isLoading = false

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - Refresh

    func refresh(for userID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        async let incomingResult = fetchRequests(
            field: "receiverID", value: userID, status: "pending"
        )
        async let outgoingResult = fetchRequests(
            field: "senderID", value: userID, status: "pending"
        )
        async let friendsResult = fetchFriendships(for: userID)

        let (incoming, outgoing, friendships) = try await (
            incomingResult, outgoingResult, friendsResult
        )

        incomingRequests = incoming
        outgoingRequests = outgoing
        friends = friendships
    }

    // MARK: - Send Request

    func sendRequest(to receiverID: String, from senderID: String) async throws {
        guard senderID != receiverID else {
            throw FriendServiceError.cannotFriendSelf
        }

        guard !isFriend(with: receiverID) else {
            throw FriendServiceError.alreadyFriends
        }

        guard pendingRequest(with: receiverID) == nil else {
            throw FriendServiceError.requestAlreadyExists
        }

        // Check for mutual request (B already sent to A)
        if let mutualRequest = try await findPendingRequest(
            senderID: receiverID, receiverID: senderID
        ) {
            try await performAccept(mutualRequest, by: senderID)
            return
        }

        let record = CKRecord(recordType: Self.requestRecordType)
        record["senderID"] = senderID
        record["receiverID"] = receiverID
        record["status"] = FriendRequestStatus.pending.rawValue

        _ = try await database.save(record)
    }

    // MARK: - Accept

    func acceptRequest(_ requestID: String, by userID: String) async throws {
        let record = try await fetchRequestRecord(requestID)
        let request = Self.friendRequest(from: record)

        guard request.isPending else {
            throw FriendServiceError.invalidTransition(
                from: request.status, to: .accepted
            )
        }

        guard request.isReceiver(userID) else {
            throw FriendServiceError.unauthorized
        }

        try await performAccept(request, by: userID)
    }

    // MARK: - Decline

    func declineRequest(_ requestID: String, by userID: String) async throws {
        let record = try await fetchRequestRecord(requestID)
        let request = Self.friendRequest(from: record)

        guard request.isPending else {
            throw FriendServiceError.invalidTransition(
                from: request.status, to: .declined
            )
        }

        guard request.isReceiver(userID) else {
            throw FriendServiceError.unauthorized
        }

        record["status"] = FriendRequestStatus.declined.rawValue
        _ = try await database.save(record)
    }

    // MARK: - Cancel

    func cancelRequest(_ requestID: String, by userID: String) async throws {
        let record = try await fetchRequestRecord(requestID)
        let request = Self.friendRequest(from: record)

        guard request.isPending else {
            throw FriendServiceError.invalidTransition(
                from: request.status, to: .cancelled
            )
        }

        guard request.isSender(userID) else {
            throw FriendServiceError.unauthorized
        }

        record["status"] = FriendRequestStatus.cancelled.rawValue
        _ = try await database.save(record)
    }

    // MARK: - Remove Friend

    func removeFriend(_ friendshipID: String) async throws {
        let recordID = CKRecord.ID(recordName: friendshipID)
        do {
            try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            throw FriendServiceError.friendshipNotFound
        }
    }

    // MARK: - Queries

    func isFriend(with userID: String) -> Bool {
        friends.contains { $0.userA == userID || $0.userB == userID }
    }

    func pendingRequest(with userID: String) -> FriendRequest? {
        let allPending = incomingRequests + outgoingRequests
        return allPending.first {
            $0.isPending && ($0.senderID == userID || $0.receiverID == userID)
        }
    }

    // MARK: - Private Helpers

    private func performAccept(
        _ request: FriendRequest,
        by userID: String
    ) async throws {
        // Update request status
        let requestRecord = try await fetchRequestRecord(request.id)
        requestRecord["status"] = FriendRequestStatus.accepted.rawValue
        _ = try await database.save(requestRecord)

        // Create friendship with deterministic record name
        let friendID = request.otherUserID(for: userID)
        let recordName = Friendship.recordName(userID1: userID, userID2: friendID)
        let friendshipRecordID = CKRecord.ID(recordName: recordName)
        let friendshipRecord = CKRecord(
            recordType: Self.friendshipRecordType,
            recordID: friendshipRecordID
        )

        let sorted = [userID, friendID].sorted()
        friendshipRecord["userA"] = sorted[0]
        friendshipRecord["userB"] = sorted[1]

        _ = try await database.save(friendshipRecord)
    }

    private func fetchRequestRecord(_ requestID: String) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: requestID)
        do {
            return try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            throw FriendServiceError.requestNotFound
        }
    }

    private func fetchRequests(
        field: String,
        value: String,
        status: String
    ) async throws -> [FriendRequest] {
        let fieldPredicate = NSPredicate(format: "%K == %@", field, value)
        let statusPredicate = NSPredicate(format: "status == %@", status)
        let compound = NSCompoundPredicate(
            andPredicateWithSubpredicates: [fieldPredicate, statusPredicate]
        )

        let query = CKQuery(recordType: Self.requestRecordType, predicate: compound)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (results, _) = try await database.records(matching: query)
        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return Self.friendRequest(from: record)
        }
    }

    private func findPendingRequest(
        senderID: String,
        receiverID: String
    ) async throws -> FriendRequest? {
        let senderPredicate = NSPredicate(format: "senderID == %@", senderID)
        let receiverPredicate = NSPredicate(format: "receiverID == %@", receiverID)
        let statusPredicate = NSPredicate(
            format: "status == %@",
            FriendRequestStatus.pending.rawValue
        )
        let compound = NSCompoundPredicate(
            andPredicateWithSubpredicates: [senderPredicate, receiverPredicate, statusPredicate]
        )

        let query = CKQuery(recordType: Self.requestRecordType, predicate: compound)
        let (results, _) = try await database.records(matching: query)

        for (_, result) in results {
            if case .success(let record) = result {
                return Self.friendRequest(from: record)
            }
        }
        return nil
    }

    private func fetchFriendships(for userID: String) async throws -> [Friendship] {
        // CloudKit public DB doesn't support OR predicates,
        // so we run two parallel queries and merge
        async let queryA = fetchFriendshipRecords(field: "userA", value: userID)
        async let queryB = fetchFriendshipRecords(field: "userB", value: userID)

        let (resultsA, resultsB) = try await (queryA, queryB)

        var seen = Set<String>()
        var merged: [Friendship] = []
        for friendship in resultsA + resultsB {
            if seen.insert(friendship.id).inserted {
                merged.append(friendship)
            }
        }
        return merged
    }

    private func fetchFriendshipRecords(
        field: String,
        value: String
    ) async throws -> [Friendship] {
        let predicate = NSPredicate(format: "%K == %@", field, value)
        let query = CKQuery(recordType: Self.friendshipRecordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query)
        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return Self.friendship(from: record)
        }
    }

    // MARK: - Record Mapping

    private static func friendRequest(from record: CKRecord) -> FriendRequest {
        FriendRequest(
            id: record.recordID.recordName,
            senderID: record["senderID"] as? String ?? "",
            receiverID: record["receiverID"] as? String ?? "",
            status: FriendRequestStatus(
                rawValue: record["status"] as? String ?? ""
            ) ?? .pending,
            createdAt: record.creationDate ?? Date(),
            modifiedAt: record.modificationDate ?? Date()
        )
    }

    private static func friendship(from record: CKRecord) -> Friendship {
        Friendship(
            id: record.recordID.recordName,
            userA: record["userA"] as? String ?? "",
            userB: record["userB"] as? String ?? "",
            createdAt: record.creationDate ?? Date()
        )
    }
}
