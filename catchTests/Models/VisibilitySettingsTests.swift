import XCTest

@MainActor
final class VisibilitySettingsTests: XCTestCase {

    func test_defaultValuesAreAllTrue() {
        let settings = VisibilitySettings.default
        XCTAssertTrue(settings.showCats)
        XCTAssertTrue(settings.showEncounters)
        XCTAssertTrue(settings.showCareEntries)
    }

    func test_customInitSetsValues() {
        let settings = VisibilitySettings(
            showCats: false,
            showEncounters: true,
            showCareEntries: false
        )
        XCTAssertFalse(settings.showCats)
        XCTAssertTrue(settings.showEncounters)
        XCTAssertFalse(settings.showCareEntries)
    }

    func test_encodeDecode_roundTrip() throws {
        let original = VisibilitySettings(
            showCats: false,
            showEncounters: true,
            showCareEntries: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VisibilitySettings.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_encodeDecode_defaultRoundTrip() throws {
        let original = VisibilitySettings.default
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VisibilitySettings.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_equatable_equalValues() {
        let a = VisibilitySettings(showCats: true, showEncounters: false, showCareEntries: true)
        let b = VisibilitySettings(showCats: true, showEncounters: false, showCareEntries: true)
        XCTAssertEqual(a, b)
    }

    func test_equatable_differentValues() {
        let a = VisibilitySettings.default
        let b = VisibilitySettings(showCats: false, showEncounters: true, showCareEntries: true)
        XCTAssertNotEqual(a, b)
    }
}
