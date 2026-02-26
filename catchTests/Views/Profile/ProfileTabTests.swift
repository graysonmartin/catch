import XCTest

@MainActor
final class ProfileTabTests: XCTestCase {

    func testAllCasesHasTwoCases() {
        XCTAssertEqual(ProfileTab.allCases.count, 2)
    }

    func testDisplayNameReturnsNonEmptyStrings() {
        for tab in ProfileTab.allCases {
            XCTAssertFalse(tab.displayName.isEmpty, "\(tab) has empty displayName")
        }
    }

    func testCasesAreCollectionAndDiary() {
        XCTAssertEqual(ProfileTab.allCases[0], .collection)
        XCTAssertEqual(ProfileTab.allCases[1], .diary)
    }
}
