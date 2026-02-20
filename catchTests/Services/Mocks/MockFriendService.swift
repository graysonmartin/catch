import Foundation
import Observation

@Observable
@MainActor
final class MockFriendService: FriendService {
    private(set) var incomingRequests: [FriendRequest] = []
    private(set) var outgoingRequests: [FriendRequest] = []
    private(set) var friends: [Friendship] = []
    private(set) var isLoading = false

    // MARK: - Call Tracking

    private(set) var sendRequestCalls: [(receiverID: String, senderID: String)] = []
    private(set) var acceptRequestCalls: [(requestID: String, userID: String)] = []
    private(set) var declineRequestCalls: [(requestID: String, userID: String)] = []
    private(set) var cancelRequestCalls: [(requestID: String, userID: String)] = []
    private(set) var removeFriendCalls: [String] = []
    private(set) var refreshCalls: [String] = []

    // MARK: - Stubs

    var sendRequestError: (any Error)?
    var acceptRequestError: (any Error)?
    var declineRequestError: (any Error)?
    var cancelRequestError: (any Error)?
    var removeFriendError: (any Error)?
    var refreshError: (any Error)?

    // MARK: - FriendService

    func sendRequest(to receiverID: String, from senderID: String) async throws {
        sendRequestCalls.append((receiverID, senderID))
        if let error = sendRequestError { throw error }
    }

    func acceptRequest(_ requestID: String, by userID: String) async throws {
        acceptRequestCalls.append((requestID, userID))
        if let error = acceptRequestError { throw error }
    }

    func declineRequest(_ requestID: String, by userID: String) async throws {
        declineRequestCalls.append((requestID, userID))
        if let error = declineRequestError { throw error }
    }

    func cancelRequest(_ requestID: String, by userID: String) async throws {
        cancelRequestCalls.append((requestID, userID))
        if let error = cancelRequestError { throw error }
    }

    func removeFriend(_ friendshipID: String) async throws {
        removeFriendCalls.append(friendshipID)
        if let error = removeFriendError { throw error }
    }

    func refresh(for userID: String) async throws {
        refreshCalls.append(userID)
        if let error = refreshError { throw error }
    }

    func isFriend(with userID: String) -> Bool {
        friends.contains { $0.userA == userID || $0.userB == userID }
    }

    func pendingRequest(with userID: String) -> FriendRequest? {
        let allPending = incomingRequests + outgoingRequests
        return allPending.first {
            $0.isPending && ($0.senderID == userID || $0.receiverID == userID)
        }
    }

    // MARK: - Test Helpers

    func simulateIncomingRequest(_ request: FriendRequest) {
        incomingRequests.append(request)
    }

    func simulateOutgoingRequest(_ request: FriendRequest) {
        outgoingRequests.append(request)
    }

    func simulateFriendship(_ friendship: Friendship) {
        friends.append(friendship)
    }

    func reset() {
        incomingRequests = []
        outgoingRequests = []
        friends = []
        sendRequestCalls = []
        acceptRequestCalls = []
        declineRequestCalls = []
        cancelRequestCalls = []
        removeFriendCalls = []
        refreshCalls = []
        sendRequestError = nil
        acceptRequestError = nil
        declineRequestError = nil
        cancelRequestError = nil
        removeFriendError = nil
        refreshError = nil
    }
}
