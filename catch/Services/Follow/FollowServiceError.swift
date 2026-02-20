import Foundation

enum FollowServiceError: LocalizedError, Equatable {
    case notSignedIn
    case cannotFollowSelf
    case alreadyFollowing
    case requestAlreadyPending
    case followNotFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "you need to sign in first"
        case .cannotFollowSelf:
            "you can't follow yourself, weirdo"
        case .alreadyFollowing:
            "you're already following this person"
        case .requestAlreadyPending:
            "request already sent, chill"
        case .followNotFound:
            "follow record not found"
        case .unauthorized:
            "you don't have permission to do that"
        }
    }
}
