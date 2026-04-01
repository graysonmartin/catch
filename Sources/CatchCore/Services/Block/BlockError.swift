import Foundation

public enum BlockError: LocalizedError, Equatable {
    case notSignedIn
    case cannotBlockSelf
    case alreadyBlocked
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "you need to sign in first"
        case .cannotBlockSelf:
            "you can't block yourself"
        case .alreadyBlocked:
            "you already blocked this user"
        case .networkError(let message):
            "block didn't go through: \(message)"
        }
    }
}
