import XCTest
@testable import CatchCore

final class LocationNameBuilderTests: XCTestCase {

    func test_buildName_allComponentsPresent() {
        let result = LocationNameBuilder.buildName(
            name: "Apple Park",
            locality: "Cupertino",
            administrativeArea: "CA"
        )
        XCTAssertEqual(result, "Apple Park, Cupertino, CA")
    }

    func test_buildName_onlyNamePresent() {
        let result = LocationNameBuilder.buildName(
            name: "Central Park",
            locality: nil,
            administrativeArea: nil
        )
        XCTAssertEqual(result, "Central Park")
    }

    func test_buildName_onlyLocalityPresent() {
        let result = LocationNameBuilder.buildName(
            name: nil,
            locality: "San Francisco",
            administrativeArea: nil
        )
        XCTAssertEqual(result, "San Francisco")
    }

    func test_buildName_onlyAdministrativeAreaPresent() {
        let result = LocationNameBuilder.buildName(
            name: nil,
            locality: nil,
            administrativeArea: "California"
        )
        XCTAssertEqual(result, "California")
    }

    func test_buildName_nameAndLocalityPresent() {
        let result = LocationNameBuilder.buildName(
            name: "Golden Gate Bridge",
            locality: "San Francisco",
            administrativeArea: nil
        )
        XCTAssertEqual(result, "Golden Gate Bridge, San Francisco")
    }

    func test_buildName_allNil_returnsEmpty() {
        let result = LocationNameBuilder.buildName(
            name: nil,
            locality: nil,
            administrativeArea: nil
        )
        XCTAssertEqual(result, "")
    }

    func test_buildName_emptyStrings_filtered() {
        let result = LocationNameBuilder.buildName(
            name: "",
            locality: "Portland",
            administrativeArea: ""
        )
        XCTAssertEqual(result, "Portland")
    }

    func test_buildName_allEmpty_returnsEmpty() {
        let result = LocationNameBuilder.buildName(
            name: "",
            locality: "",
            administrativeArea: ""
        )
        XCTAssertEqual(result, "")
    }

    func test_buildName_localityAndAreaPresent() {
        let result = LocationNameBuilder.buildName(
            name: nil,
            locality: "Austin",
            administrativeArea: "TX"
        )
        XCTAssertEqual(result, "Austin, TX")
    }
}
