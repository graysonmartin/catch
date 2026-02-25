import Foundation

enum UserBrowseError: Error, Sendable, Equatable {
    case userNotFound
    case profileIsPrivate
    case networkError(String)

    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "couldn't find that user"
        case .profileIsPrivate:
            return "this profile is private"
        case .networkError(let message):
            return message
        }
    }
}
