import XCTest

final class LocationTests: XCTestCase {

    func test_hasCoordinates_falseWhenBothNil() {
        let location = Location(name: "Somewhere")
        XCTAssertFalse(location.hasCoordinates)
    }

    func test_hasCoordinates_falseWhenOnlyLatitude() {
        let location = Location(name: "Somewhere", latitude: 37.0, longitude: nil)
        XCTAssertFalse(location.hasCoordinates)
    }

    func test_hasCoordinates_falseWhenOnlyLongitude() {
        let location = Location(name: "Somewhere", latitude: nil, longitude: -122.0)
        XCTAssertFalse(location.hasCoordinates)
    }

    func test_hasCoordinates_trueWhenBothPresent() {
        let location = Location(name: "Somewhere", latitude: 37.0, longitude: -122.0)
        XCTAssertTrue(location.hasCoordinates)
    }

    func test_empty_hasEmptyNameAndNoCoordinates() {
        let location = Location.empty
        XCTAssertEqual(location.name, "")
        XCTAssertFalse(location.hasCoordinates)
    }

    func test_codableRoundtrip_withCoordinates() throws {
        let original = Location(name: "Rooftop", latitude: 37.334722, longitude: -122.008889)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Location.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_codableRoundtrip_withoutCoordinates() throws {
        let original = Location(name: "Somewhere vague")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Location.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_equality_sameValues() {
        let a = Location(name: "Alley", latitude: 37.0, longitude: -122.0)
        let b = Location(name: "Alley", latitude: 37.0, longitude: -122.0)
        XCTAssertEqual(a, b)
    }

    func test_equality_differentName() {
        let a = Location(name: "Alley", latitude: 37.0, longitude: -122.0)
        let b = Location(name: "Rooftop", latitude: 37.0, longitude: -122.0)
        XCTAssertNotEqual(a, b)
    }
}
