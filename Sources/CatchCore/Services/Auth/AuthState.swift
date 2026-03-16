import Foundation

public enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
    case email
}

public struct AuthUser: Codable, Equatable, Sendable {
    public let id: String
    public let email: String?
    public let fullName: String?
    public let provider: AuthProvider

    public init(id: String, email: String?, fullName: String?, provider: AuthProvider) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.provider = provider
    }
}

/// Legacy alias — existing code that references `AppleUser` continues to compile.
/// Prefer `AuthUser` in new code.
public typealias AppleUser = AuthUser

public enum AuthState: Equatable, Sendable {
    case unknown
    case signedIn(AuthUser)
    case signedOut

    public var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    public var user: AuthUser? {
        if case .signedIn(let user) = self { return user }
        return nil
    }
}
