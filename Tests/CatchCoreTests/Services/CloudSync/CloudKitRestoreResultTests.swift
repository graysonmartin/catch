import XCTest
@testable import CatchCore

final class CloudKitRestoreResultTests: XCTestCase {

    func testIsEmptyWhenBothCountsAreZero() {
        let result = CloudKitRestoreResult(catsRestored: 0, encountersRestored: 0)
        XCTAssertTrue(result.isEmpty)
    }

    func testIsNotEmptyWhenCatsRestored() {
        let result = CloudKitRestoreResult(catsRestored: 3, encountersRestored: 0)
        XCTAssertFalse(result.isEmpty)
    }

    func testIsNotEmptyWhenEncountersRestored() {
        let result = CloudKitRestoreResult(catsRestored: 0, encountersRestored: 5)
        XCTAssertFalse(result.isEmpty)
    }

    func testIsNotEmptyWhenBothRestored() {
        let result = CloudKitRestoreResult(catsRestored: 2, encountersRestored: 4)
        XCTAssertFalse(result.isEmpty)
    }

    func testEquality() {
        let a = CloudKitRestoreResult(catsRestored: 1, encountersRestored: 2)
        let b = CloudKitRestoreResult(catsRestored: 1, encountersRestored: 2)
        let c = CloudKitRestoreResult(catsRestored: 3, encountersRestored: 2)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
