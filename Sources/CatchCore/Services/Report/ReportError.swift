import Foundation

public enum ReportError: LocalizedError, Equatable {
    case notSignedIn
    case alreadyReported
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            "you need to sign in first"
        case .alreadyReported:
            "you already reported this one"
        case .networkError(let message):
            "report didn't go through: \(message)"
        }
    }
}
