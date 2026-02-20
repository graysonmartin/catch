import XCTest

@MainActor
final class FriendServiceErrorTests: XCTestCase {

    func test_allCases_haveDescriptions() {
        let cases: [FriendServiceError] = [
            .notSignedIn,
            .cannotFriendSelf,
            .requestAlreadyExists,
            .alreadyFriends,
            .requestNotFound,
            .friendshipNotFound,
            .invalidTransition(from: .pending, to: .accepted),
            .unauthorized,
        ]

        for error in cases {
            XCTAssertNotNil(error.errorDescription, "\(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) description should not be empty")
        }
    }

    func test_equatable_sameCase() {
        XCTAssertEqual(FriendServiceError.notSignedIn, .notSignedIn)
        XCTAssertEqual(FriendServiceError.cannotFriendSelf, .cannotFriendSelf)
        XCTAssertEqual(FriendServiceError.requestAlreadyExists, .requestAlreadyExists)
        XCTAssertEqual(FriendServiceError.alreadyFriends, .alreadyFriends)
        XCTAssertEqual(FriendServiceError.requestNotFound, .requestNotFound)
        XCTAssertEqual(FriendServiceError.friendshipNotFound, .friendshipNotFound)
        XCTAssertEqual(FriendServiceError.unauthorized, .unauthorized)
    }

    func test_equatable_differentCase() {
        XCTAssertNotEqual(FriendServiceError.notSignedIn, .cannotFriendSelf)
        XCTAssertNotEqual(FriendServiceError.requestNotFound, .friendshipNotFound)
    }

    func test_invalidTransition_equatable() {
        let a = FriendServiceError.invalidTransition(from: .pending, to: .accepted)
        let b = FriendServiceError.invalidTransition(from: .pending, to: .accepted)
        let c = FriendServiceError.invalidTransition(from: .pending, to: .declined)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func test_invalidTransition_description() {
        let error = FriendServiceError.invalidTransition(from: .pending, to: .cancelled)
        XCTAssertEqual(
            error.errorDescription,
            "Can't change request from pending to cancelled."
        )
    }
}
