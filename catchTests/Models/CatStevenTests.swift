import XCTest

@MainActor
final class CatStevenTests: XCTestCase {

    // MARK: - isSteven: positive cases

    func test_isSteven_stevenDomesticShorthair() {
        let cat = Cat(name: "Steven", breed: "Domestic Shorthair")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_uppercaseStevenDomesticShorthair() {
        let cat = Cat(name: "STEVEN", breed: "Domestic Shorthair")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_steveDomesticShorthair() {
        let cat = Cat(name: "steve", breed: "Domestic Shorthair")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_stephenDomesticShorthair() {
        let cat = Cat(name: "stephen", breed: "Domestic Shorthair")
        XCTAssertTrue(cat.isSteven)
    }

    func test_isSteven_whitespaceSteven() {
        let cat = Cat(name: " Steven ", breed: "Domestic Shorthair")
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

    func test_isSteven_wrongNameDomesticShorthair() {
        let cat = Cat(name: "Whiskers", breed: "Domestic Shorthair")
        XCTAssertFalse(cat.isSteven)
    }
}
