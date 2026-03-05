import Foundation

public enum UsernameAvailability {
    case idle
    case checking
    case available
    case taken
    case error
}

public enum UsernameValidationResult: Equatable {
    case valid
    case tooShort
    case tooLong
    case invalidCharacters
    case empty
}

public enum UsernameValidator {
    private static let minLength = 3
    private static let maxLength = 20
    private static let allowedPattern = /^[a-z0-9_]+$/

    private static let reservedUsernames: Set<String> = [
        "grayson", "sophi", "bea", "tuong", "mark", "shiv",
        "tatum", "jorge", "raffaele", "bella", "2hollis",
        "bladee", "stacey", "terry", "bubi", "thacatfish"
    ]

    public static func validate(_ username: String) -> UsernameValidationResult {
        guard !username.isEmpty else { return .empty }
        guard username.count >= minLength else { return .tooShort }
        guard username.count <= maxLength else { return .tooLong }
        guard username.wholeMatch(of: allowedPattern) != nil else { return .invalidCharacters }
        return .valid
    }

    /// Returns `true` if the username is in the pre-launch reserved list.
    /// Reserved usernames appear as "taken" during availability checks
    /// unless the name was already assigned to the current user server-side.
    public static func isReserved(_ username: String) -> Bool {
        reservedUsernames.contains(username.lowercased())
    }

    public static func formatDisplay(_ username: String) -> String {
        "@\(username)"
    }
}
