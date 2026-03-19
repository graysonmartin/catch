import XCTest
@testable import CatchCore

final class ReportCategoryTests: XCTestCase {

    func testRawValuesMatchDatabaseConstraint() {
        let expected: Set<String> = ["spam", "inappropriate", "harassment", "other"]
        let actual = Set(ReportCategory.allCases.map(\.rawValue))
        XCTAssertEqual(actual, expected)
    }

    func testAllCasesCount() {
        XCTAssertEqual(ReportCategory.allCases.count, 4)
    }

    func testRawValueRoundTrip() {
        for category in ReportCategory.allCases {
            XCTAssertEqual(ReportCategory(rawValue: category.rawValue), category)
        }
    }
}
