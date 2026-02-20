import Foundation

struct AppleUser: Codable, Equatable, Sendable {
    let userIdentifier: String
    let fullName: String?
    let email: String?
}

enum AuthState: Equatable, Sendable {
    case unknown
    case signedIn(AppleUser)
    case signedOut

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    var user: AppleUser? {
        if case .signedIn(let user) = self { return user }
        return nil
    }
}
