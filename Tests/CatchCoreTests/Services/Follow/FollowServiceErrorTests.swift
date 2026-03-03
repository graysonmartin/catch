import XCTest
@testable import CatchCore

@MainActor
final class FollowServiceErrorTests: XCTestCase {

    func test_allCases_haveNonNilErrorDescriptions() {
        let cases: [FollowServiceError] = [
            .notSignedIn,
            .cannotFollowSelf,
            .alreadyFollowing,
            .requestAlreadyPending,
            .followNotFound,
            .unauthorized,
            .rateLimited(retryAfter: 10)
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func test_equatable_matchesSameCase() {
        XCTAssertEqual(FollowServiceError.notSignedIn, .notSignedIn)
        XCTAssertEqual(FollowServiceError.cannotFollowSelf, .cannotFollowSelf)
        XCTAssertEqual(FollowServiceError.alreadyFollowing, .alreadyFollowing)
        XCTAssertEqual(FollowServiceError.requestAlreadyPending, .requestAlreadyPending)
        XCTAssertEqual(FollowServiceError.followNotFound, .followNotFound)
        XCTAssertEqual(FollowServiceError.unauthorized, .unauthorized)
    }

    func test_equatable_differsBetweenCases() {
        XCTAssertNotEqual(FollowServiceError.notSignedIn, .cannotFollowSelf)
        XCTAssertNotEqual(FollowServiceError.alreadyFollowing, .requestAlreadyPending)
    }
}
