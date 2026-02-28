import XCTest
@testable import CatchCore

final class PaginatedResultTests: XCTestCase {

    func testInitWithItemsAndHasMore() {
        let result = PaginatedResult(items: ["a", "b", "c"], hasMore: true)

        XCTAssertEqual(result.items, ["a", "b", "c"])
        XCTAssertTrue(result.hasMore)
    }

    func testInitWithEmptyItemsAndNoMore() {
        let result = PaginatedResult<String>(items: [], hasMore: false)

        XCTAssertTrue(result.items.isEmpty)
        XCTAssertFalse(result.hasMore)
    }

    func testPaginationConstantsDefaultPageSize() {
        XCTAssertEqual(PaginationConstants.defaultPageSize, 20)
    }

    func testPaginationConstantsCommentsPageSize() {
        XCTAssertEqual(PaginationConstants.commentsPageSize, 20)
    }

    func testPaginationConstantsMaxEncountersPerUser() {
        XCTAssertEqual(PaginationConstants.maxEncountersPerUser, 20)
    }
}
