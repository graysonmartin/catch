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
        let user = AppleUser(userIdentifier: "abc123", fullName: "Test", email: "t@t.com")
        let state = AuthState.signedIn(user)
        XCTAssertTrue(state.isSignedIn)
        XCTAssertEqual(state.user, user)
    }

    func test_signedIn_userExtraction() {
        let user = AppleUser(userIdentifier: "id", fullName: nil, email: nil)
        let state = AuthState.signedIn(user)
        XCTAssertEqual(state.user?.userIdentifier, "id")
        XCTAssertNil(state.user?.fullName)
        XCTAssertNil(state.user?.email)
    }

    // MARK: - AppleUser Codable

    func test_appleUser_codableRoundTrip_allFields() throws {
        let user = AppleUser(userIdentifier: "user-1", fullName: "Cat Person", email: "cat@catch.app")
        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(AppleUser.self, from: data)
        XCTAssertEqual(decoded, user)
    }

    func test_appleUser_codableRoundTrip_nilOptionals() throws {
        let user = AppleUser(userIdentifier: "user-2", fullName: nil, email: nil)
        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(AppleUser.self, from: data)
        XCTAssertEqual(decoded, user)
        XCTAssertNil(decoded.fullName)
        XCTAssertNil(decoded.email)
    }

    func test_appleUser_equatable() {
        let a = AppleUser(userIdentifier: "same", fullName: "Name", email: "e@e.com")
        let b = AppleUser(userIdentifier: "same", fullName: "Name", email: "e@e.com")
        let c = AppleUser(userIdentifier: "different", fullName: "Name", email: "e@e.com")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - AuthState Equatable

    func test_authState_equatable() {
        let user = AppleUser(userIdentifier: "id", fullName: nil, email: nil)
        XCTAssertEqual(AuthState.unknown, AuthState.unknown)
        XCTAssertEqual(AuthState.signedOut, AuthState.signedOut)
        XCTAssertEqual(AuthState.signedIn(user), AuthState.signedIn(user))
        XCTAssertNotEqual(AuthState.unknown, AuthState.signedOut)
        XCTAssertNotEqual(AuthState.signedOut, AuthState.signedIn(user))
    }
}
