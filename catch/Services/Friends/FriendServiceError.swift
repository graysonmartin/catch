import Foundation

enum FriendServiceError: LocalizedError, Equatable {
    case notSignedIn
    case cannotFriendSelf
    case requestAlreadyExists
    case alreadyFriends
    case requestNotFound
    case friendshipNotFound
    case invalidTransition(from: FriendRequestStatus, to: FriendRequestStatus)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You must be signed in to manage friends."
        case .cannotFriendSelf:
            return "You can't send a friend request to yourself."
        case .requestAlreadyExists:
            return "A friend request already exists with this user."
        case .alreadyFriends:
            return "You're already friends with this user."
        case .requestNotFound:
            return "Friend request not found."
        case .friendshipNotFound:
            return "Friendship not found."
        case .invalidTransition(let from, let to):
            return "Can't change request from \(from.rawValue) to \(to.rawValue)."
        case .unauthorized:
            return "You don't have permission for this action."
        }
    }
}
