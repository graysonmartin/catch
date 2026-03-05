import XCTest
@testable import CatchCore

final class LocationSearchResultTests: XCTestCase {

    func test_displayName_withSubtitle_combinesTitleAndSubtitle() {
        let result = LocationSearchResult(title: "Geneva", subtitle: "Switzerland")
        XCTAssertEqual(result.displayName, "Geneva, Switzerland")
    }

    func test_displayName_withoutSubtitle_returnsTitleOnly() {
        let result = LocationSearchResult(title: "Geneva", subtitle: "")
        XCTAssertEqual(result.displayName, "Geneva")
    }

    func test_hashable_equalResults_haveSameHash() {
        let a = LocationSearchResult(title: "Paris", subtitle: "France")
        let b = LocationSearchResult(title: "Paris", subtitle: "France")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func test_hashable_differentResults_areNotEqual() {
        let a = LocationSearchResult(title: "Paris", subtitle: "France")
        let b = LocationSearchResult(title: "Paris", subtitle: "Texas, United States")
        XCTAssertNotEqual(a, b)
    }

    func test_displayName_longSubtitle() {
        let result = LocationSearchResult(
            title: "Central Park",
            subtitle: "New York, NY, United States"
        )
        XCTAssertEqual(result.displayName, "Central Park, New York, NY, United States")
    }
}
