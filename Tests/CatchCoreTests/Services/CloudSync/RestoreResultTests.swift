import XCTest
@testable import CatchCore

final class RestoreResultTests: XCTestCase {

    func testIsEmptyWhenBothCountsAreZero() {
        let result = RestoreResult(catsRestored: 0, encountersRestored: 0)
        XCTAssertTrue(result.isEmpty)
    }

    func testIsNotEmptyWhenCatsRestored() {
        let result = RestoreResult(catsRestored: 3, encountersRestored: 0)
        XCTAssertFalse(result.isEmpty)
    }

    func testIsNotEmptyWhenEncountersRestored() {
        let result = RestoreResult(catsRestored: 0, encountersRestored: 5)
        XCTAssertFalse(result.isEmpty)
    }

    func testIsNotEmptyWhenBothRestored() {
        let result = RestoreResult(catsRestored: 2, encountersRestored: 4)
        XCTAssertFalse(result.isEmpty)
    }

    func testEquality() {
        let a = RestoreResult(catsRestored: 1, encountersRestored: 2)
        let b = RestoreResult(catsRestored: 1, encountersRestored: 2)
        let c = RestoreResult(catsRestored: 3, encountersRestored: 2)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
