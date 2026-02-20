import Foundation

struct FriendRequest: Sendable, Equatable, Identifiable {
    let id: String
    let senderID: String
    let receiverID: String
    let status: FriendRequestStatus
    let createdAt: Date
    let modifiedAt: Date

    var isPending: Bool {
        status == .pending
    }

    var isAccepted: Bool {
        status == .accepted
    }

    var isDeclined: Bool {
        status == .declined
    }

    var isCancelled: Bool {
        status == .cancelled
    }

    func isSender(_ userID: String) -> Bool {
        senderID == userID
    }

    func isReceiver(_ userID: String) -> Bool {
        receiverID == userID
    }

    func otherUserID(for currentUserID: String) -> String {
        currentUserID == senderID ? receiverID : senderID
    }
}
