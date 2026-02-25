import XCTest

@MainActor
final class CatStevenTests: XCTestCase {

    // MARK: - isSteven: positive cases

    func test_isSteven_stevenTabby() {
        let cat = Cat(name: "Steven", breed: "Tabby")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_uppercaseStevenTigerTabby() {
        let cat = Cat(name: "STEVEN", breed: "Tiger Tabby")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_steveTabby() {
        let cat = Cat(name: "steve", breed: "Tabby")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_stephenTabby() {
        let cat = Cat(name: "stephen", breed: "Tabby")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_whitespaceSteven() {
        let cat = Cat(name: " Steven ", breed: "Tabby")
        XCTAssertTrue(cat.isSteven)
    }

    // MARK: - isSteven: negative cases

    func test_isSteven_stevenWrongBreed() {
        let cat = Cat(name: "Steven", breed: "Persian")
        XCTAssertFalse(cat.isSteven)
    }

    func test_isSteven_stevenNilBreed() {
        let cat = Cat(name: "Steven")
        XCTAssertFalse(cat.isSteven)
    }

    func test_isSteven_wrongNameTabby() {
        let cat = Cat(name: "Whiskers", breed: "Tabby")
        XCTAssertFalse(cat.isSteven)
    }
}
