import XCTest

@MainActor
final class CloudSyncErrorTests: XCTestCase {

    func test_allCases_haveNonNilErrorDescriptions() {
        let cases: [CloudSyncError] = [
            .notSignedIn,
            .recordNotFound,
            .uploadFailed,
            .fetchFailed
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func test_equatable_matchesSameCase() {
        XCTAssertEqual(CloudSyncError.notSignedIn, .notSignedIn)
        XCTAssertEqual(CloudSyncError.recordNotFound, .recordNotFound)
        XCTAssertEqual(CloudSyncError.uploadFailed, .uploadFailed)
        XCTAssertEqual(CloudSyncError.fetchFailed, .fetchFailed)
    }

    func test_equatable_differsBetweenCases() {
        XCTAssertNotEqual(CloudSyncError.notSignedIn, .uploadFailed)
        XCTAssertNotEqual(CloudSyncError.recordNotFound, .fetchFailed)
    }
}
