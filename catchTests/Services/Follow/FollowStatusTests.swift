import XCTest

@MainActor
final class FollowStatusTests: XCTestCase {

    func test_allCases_containsActiveAndPending() {
        let cases = FollowStatus.allCases
        XCTAssertEqual(cases.count, 2)
        XCTAssertTrue(cases.contains(.active))
        XCTAssertTrue(cases.contains(.pending))
    }

    func test_rawValues_matchExpectedStrings() {
        XCTAssertEqual(FollowStatus.active.rawValue, "active")
        XCTAssertEqual(FollowStatus.pending.rawValue, "pending")
    }

    func test_initFromRawValue_roundTrips() {
        XCTAssertEqual(FollowStatus(rawValue: "active"), .active)
        XCTAssertEqual(FollowStatus(rawValue: "pending"), .pending)
        XCTAssertNil(FollowStatus(rawValue: "bogus"))
    }
}
