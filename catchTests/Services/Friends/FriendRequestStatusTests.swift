import XCTest

@MainActor
final class FriendRequestStatusTests: XCTestCase {

    func test_rawValues() {
        XCTAssertEqual(FriendRequestStatus.pending.rawValue, "pending")
        XCTAssertEqual(FriendRequestStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(FriendRequestStatus.declined.rawValue, "declined")
        XCTAssertEqual(FriendRequestStatus.cancelled.rawValue, "cancelled")
    }

    func test_initFromRawValue() {
        XCTAssertEqual(FriendRequestStatus(rawValue: "pending"), .pending)
        XCTAssertEqual(FriendRequestStatus(rawValue: "accepted"), .accepted)
        XCTAssertEqual(FriendRequestStatus(rawValue: "declined"), .declined)
        XCTAssertEqual(FriendRequestStatus(rawValue: "cancelled"), .cancelled)
        XCTAssertNil(FriendRequestStatus(rawValue: "bogus"))
    }

    func test_caseIterable() {
        let allCases = FriendRequestStatus.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.accepted))
        XCTAssertTrue(allCases.contains(.declined))
        XCTAssertTrue(allCases.contains(.cancelled))
    }

    func test_isTerminal() {
        XCTAssertFalse(FriendRequestStatus.pending.isTerminal)
        XCTAssertTrue(FriendRequestStatus.accepted.isTerminal)
        XCTAssertTrue(FriendRequestStatus.declined.isTerminal)
        XCTAssertTrue(FriendRequestStatus.cancelled.isTerminal)
    }

    func test_displayName() {
        for status in FriendRequestStatus.allCases {
            XCTAssertEqual(status.displayName, status.rawValue)
        }
    }
}
