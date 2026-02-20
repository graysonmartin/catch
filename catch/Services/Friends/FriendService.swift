import Foundation

@MainActor
protocol FriendService: Observable, Sendable {
    var incomingRequests: [FriendRequest] { get }
    var outgoingRequests: [FriendRequest] { get }
    var friends: [Friendship] { get }
    var isLoading: Bool { get }

    func sendRequest(to receiverID: String, from senderID: String) async throws
    func acceptRequest(_ requestID: String, by userID: String) async throws
    func declineRequest(_ requestID: String, by userID: String) async throws
    func cancelRequest(_ requestID: String, by userID: String) async throws
    func removeFriend(_ friendshipID: String) async throws
    func refresh(for userID: String) async throws
    func isFriend(with userID: String) -> Bool
    func pendingRequest(with userID: String) -> FriendRequest?
}
