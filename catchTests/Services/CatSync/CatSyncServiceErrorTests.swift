import XCTest

@MainActor
final class CatSyncServiceErrorTests: XCTestCase {

    func test_allCases_haveNonNilErrorDescriptions() {
        let cases: [CatSyncServiceError] = [
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
        XCTAssertEqual(CatSyncServiceError.notSignedIn, .notSignedIn)
        XCTAssertEqual(CatSyncServiceError.recordNotFound, .recordNotFound)
        XCTAssertEqual(CatSyncServiceError.uploadFailed, .uploadFailed)
        XCTAssertEqual(CatSyncServiceError.fetchFailed, .fetchFailed)
    }

    func test_equatable_differsBetweenCases() {
        XCTAssertNotEqual(CatSyncServiceError.notSignedIn, .uploadFailed)
        XCTAssertNotEqual(CatSyncServiceError.recordNotFound, .fetchFailed)
    }
}
