import XCTest

final class BreedLabelMapperTests: XCTestCase {

    func test_displayName_knownBreedReturnsMappedName() {
        XCTAssertEqual(BreedLabelMapper.displayName(for: "tabby"), "Tabby")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Persian_cat"), "Persian")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Siamese_cat"), "Siamese")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Maine_Coon"), "Maine Coon")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Egyptian_cat"), "Egyptian Mau")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Russian_Blue"), "Russian Blue")
    }

    func test_displayName_unknownIdentifierReturnsNil() {
        XCTAssertNil(BreedLabelMapper.displayName(for: "golden_retriever"))
        XCTAssertNil(BreedLabelMapper.displayName(for: "banana"))
        XCTAssertNil(BreedLabelMapper.displayName(for: ""))
    }

    func test_isCatBreed_trueForKnownBreeds() {
        XCTAssertTrue(BreedLabelMapper.isCatBreed("tabby"))
        XCTAssertTrue(BreedLabelMapper.isCatBreed("Ragdoll"))
        XCTAssertTrue(BreedLabelMapper.isCatBreed("Sphynx"))
    }

    func test_isCatBreed_falseForNonCatIdentifiers() {
        XCTAssertFalse(BreedLabelMapper.isCatBreed("golden_retriever"))
        XCTAssertFalse(BreedLabelMapper.isCatBreed("toaster"))
        XCTAssertFalse(BreedLabelMapper.isCatBreed(""))
    }

    func test_allDisplayNames_isNotEmpty() {
        XCTAssertFalse(BreedLabelMapper.allDisplayNames.isEmpty)
    }

    func test_allDisplayNames_isSorted() {
        let names = BreedLabelMapper.allDisplayNames
        XCTAssertEqual(names, names.sorted())
    }

    func test_allDisplayNames_containsExpectedBreeds() {
        let names = BreedLabelMapper.allDisplayNames
        XCTAssertTrue(names.contains("Tabby"))
        XCTAssertTrue(names.contains("Persian"))
        XCTAssertTrue(names.contains("Siamese"))
        XCTAssertTrue(names.contains("Maine Coon"))
    }
}
