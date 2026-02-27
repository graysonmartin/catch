import Foundation

public struct AppleUser: Codable, Equatable, Sendable {
    public let userIdentifier: String
    public let fullName: String?
    public let email: String?

    public init(userIdentifier: String, fullName: String?, email: String?) {
        self.userIdentifier = userIdentifier
        self.fullName = fullName
        self.email = email
    }
}

public enum AuthState: Equatable, Sendable {
    case unknown
    case signedIn(AppleUser)
    case signedOut

    public var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    public var user: AppleUser? {
        if case .signedIn(let user) = self { return user }
        return nil
    }
}
