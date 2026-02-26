import Foundation

enum SocialInteractionError: LocalizedError, Equatable {
    case notSignedIn
    case encounterNotSynced
    case commentEmpty
    case commentTooLong
    case commentNotFound
    case unauthorized
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "you need to sign in first"
        case .encounterNotSynced:
            "this encounter hasn't synced to the cloud yet"
        case .commentEmpty:
            "you gotta actually write something"
        case .commentTooLong:
            "that's way too long, keep it under 500 chars"
        case .commentNotFound:
            "that comment doesn't exist anymore"
        case .unauthorized:
            "you can't do that"
        case .networkError(let message):
            "something went wrong: \(message)"
        }
    }
}
