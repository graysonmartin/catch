import XCTest
@testable import CatchCore

@MainActor
final class AppearanceModeTests: XCTestCase {

    func test_allCases_containsThreeOptions() {
        XCTAssertEqual(AppearanceMode.allCases.count, 3)
    }

    func test_rawValues_areCorrect() {
        XCTAssertEqual(AppearanceMode.system.rawValue, "system")
        XCTAssertEqual(AppearanceMode.light.rawValue, "light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "dark")
    }

    func test_initFromRawValue_system() {
        XCTAssertEqual(AppearanceMode(rawValue: "system"), .system)
    }

    func test_initFromRawValue_light() {
        XCTAssertEqual(AppearanceMode(rawValue: "light"), .light)
    }

    func test_initFromRawValue_dark() {
        XCTAssertEqual(AppearanceMode(rawValue: "dark"), .dark)
    }

    func test_initFromInvalidRawValue_returnsNil() {
        XCTAssertNil(AppearanceMode(rawValue: "neon"))
    }
}
