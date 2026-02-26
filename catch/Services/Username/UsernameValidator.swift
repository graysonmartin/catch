import Foundation

enum UsernameAvailability {
    case idle
    case checking
    case available
    case taken
}

enum UsernameValidationResult: Equatable {
    case valid
    case tooShort
    case tooLong
    case invalidCharacters
    case empty
}

enum UsernameValidator {
    private static let minLength = 3
    private static let maxLength = 20
    private static let allowedPattern = /^[a-z0-9_]+$/

    static func validate(_ username: String) -> UsernameValidationResult {
        guard !username.isEmpty else { return .empty }
        guard username.count >= minLength else { return .tooShort }
        guard username.count <= maxLength else { return .tooLong }
        guard username.wholeMatch(of: allowedPattern) != nil else { return .invalidCharacters }
        return .valid
    }

    static func formatDisplay(_ username: String) -> String {
        "@\(username)"
    }
}
