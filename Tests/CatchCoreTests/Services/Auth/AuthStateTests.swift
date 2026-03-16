import XCTest
@testable import CatchCore

@MainActor
final class AuthStateTests: XCTestCase {

    // MARK: - AuthState

    func test_unknown_isNotSignedIn() {
        let state = AuthState.unknown
        XCTAssertFalse(state.isSignedIn)
        XCTAssertNil(state.user)
    }

    func test_signedOut_isNotSignedIn() {
        let state = AuthState.signedOut
        XCTAssertFalse(state.isSignedIn)
        XCTAssertNil(state.user)
    }

    func test_signedIn_isSignedIn() {
        let user = AuthUser(id: "abc123", email: "t@t.com", fullName: "Test", provider: .apple)
        let state = AuthState.signedIn(user)
        XCTAssertTrue(state.isSignedIn)
        XCTAssertEqual(state.user, user)
    }

    func test_signedIn_userExtraction() {
        let user = AuthUser(id: "id", email: nil, fullName: nil, provider: .apple)
        let state = AuthState.signedIn(user)
        XCTAssertEqual(state.user?.id, "id")
        XCTAssertNil(state.user?.fullName)
        XCTAssertNil(state.user?.email)
    }

    // MARK: - AuthUser Codable

    func test_authUser_codableRoundTrip_allFields() throws {
        let user = AuthUser(id: "user-1", email: "cat@catch.app", fullName: "Cat Person", provider: .apple)
        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(AuthUser.self, from: data)
        XCTAssertEqual(decoded, user)
    }

    func test_authUser_codableRoundTrip_nilOptionals() throws {
        let user = AuthUser(id: "user-2", email: nil, fullName: nil, provider: .email)
        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(AuthUser.self, from: data)
        XCTAssertEqual(decoded, user)
        XCTAssertNil(decoded.fullName)
        XCTAssertNil(decoded.email)
    }

    func test_authUser_equatable() {
        let a = AuthUser(id: "same", email: "e@e.com", fullName: "Name", provider: .apple)
        let b = AuthUser(id: "same", email: "e@e.com", fullName: "Name", provider: .apple)
        let c = AuthUser(id: "different", email: "e@e.com", fullName: "Name", provider: .apple)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - AuthProvider

    func test_authProvider_codableRoundTrip() throws {
        for provider in [AuthProvider.apple, .google, .email] {
            let data = try JSONEncoder().encode(provider)
            let decoded = try JSONDecoder().decode(AuthProvider.self, from: data)
            XCTAssertEqual(decoded, provider)
        }
    }

    // MARK: - AuthState Equatable

    func test_authState_equatable() {
        let user = AuthUser(id: "id", email: nil, fullName: nil, provider: .apple)
        XCTAssertEqual(AuthState.unknown, AuthState.unknown)
        XCTAssertEqual(AuthState.signedOut, AuthState.signedOut)
        XCTAssertEqual(AuthState.signedIn(user), AuthState.signedIn(user))
        XCTAssertNotEqual(AuthState.unknown, AuthState.signedOut)
        XCTAssertNotEqual(AuthState.signedOut, AuthState.signedIn(user))
    }

    // MARK: - Legacy Typealias

    func test_appleUser_typealiasWorks() {
        let user: AppleUser = AuthUser(id: "legacy", email: nil, fullName: nil, provider: .apple)
        XCTAssertEqual(user.id, "legacy")
    }
}
