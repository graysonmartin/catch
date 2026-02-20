import Foundation

enum FriendRequestStatus: String, CaseIterable, Sendable, Equatable {
    case pending
    case accepted
    case declined
    case cancelled

    var isTerminal: Bool {
        switch self {
        case .pending:
            return false
        case .accepted, .declined, .cancelled:
            return true
        }
    }

    var displayName: String {
        rawValue
    }
}
