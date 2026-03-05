import XCTest
@testable import CatchCore

final class ReferenceBackfillResultTests: XCTestCase {

    func test_totalUpdated_sumsAllCounts() {
        let result = ReferenceBackfillService.BackfillResult(
            encountersUpdated: 5,
            commentsUpdated: 3,
            likesUpdated: 2
        )

        XCTAssertEqual(result.totalUpdated, 10)
    }

    func test_isFullyBackfilled_trueWhenNoUpdates() {
        let result = ReferenceBackfillService.BackfillResult(
            encountersUpdated: 0,
            commentsUpdated: 0,
            likesUpdated: 0
        )

        XCTAssertTrue(result.isFullyBackfilled)
    }

    func test_isFullyBackfilled_falseWhenAnyUpdated() {
        let result = ReferenceBackfillService.BackfillResult(
            encountersUpdated: 1,
            commentsUpdated: 0,
            likesUpdated: 0
        )

        XCTAssertFalse(result.isFullyBackfilled)
    }

    func test_equatable() {
        let a = ReferenceBackfillService.BackfillResult(
            encountersUpdated: 1, commentsUpdated: 2, likesUpdated: 3
        )
        let b = ReferenceBackfillService.BackfillResult(
            encountersUpdated: 1, commentsUpdated: 2, likesUpdated: 3
        )
        let c = ReferenceBackfillService.BackfillResult(
            encountersUpdated: 0, commentsUpdated: 0, likesUpdated: 0
        )

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
