import XCTest
@testable import CatchCore

final class BreedLabelMapperTests: XCTestCase {

    func test_displayName_knownModelLabelsReturnMappedName() {
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Abyssinian"), "Abyssinian")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Bengal"), "Bengal")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Bombay"), "Bombay")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "British_Shorthair"), "British Shorthair")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Domestic_Shorthair"), "Domestic Shorthair")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Maine_Coon"), "Maine Coon")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Persian"), "Persian")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Ragdoll"), "Ragdoll")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Russian_Blue"), "Russian Blue")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Scottish_Fold"), "Scottish Fold")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Siamese"), "Siamese")
        XCTAssertEqual(BreedLabelMapper.displayName(for: "Sphynx"), "Sphynx")
    }

    func test_displayName_oldVisionLabelsReturnNil() {
        XCTAssertNil(BreedLabelMapper.displayName(for: "tabby"))
        XCTAssertNil(BreedLabelMapper.displayName(for: "Persian_cat"))
        XCTAssertNil(BreedLabelMapper.displayName(for: "Siamese_cat"))
        XCTAssertNil(BreedLabelMapper.displayName(for: "Egyptian_cat"))
        XCTAssertNil(BreedLabelMapper.displayName(for: "tiger_cat"))
    }

    func test_displayName_unknownIdentifierReturnsNil() {
        XCTAssertNil(BreedLabelMapper.displayName(for: "golden_retriever"))
        XCTAssertNil(BreedLabelMapper.displayName(for: "banana"))
        XCTAssertNil(BreedLabelMapper.displayName(for: ""))
    }

    func test_isCatBreed_trueForModelLabels() {
        XCTAssertTrue(BreedLabelMapper.isCatBreed("Ragdoll"))
        XCTAssertTrue(BreedLabelMapper.isCatBreed("Sphynx"))
        XCTAssertTrue(BreedLabelMapper.isCatBreed("Maine_Coon"))
        XCTAssertTrue(BreedLabelMapper.isCatBreed("Domestic_Shorthair"))
    }

    func test_isCatBreed_falseForNonModelIdentifiers() {
        XCTAssertFalse(BreedLabelMapper.isCatBreed("golden_retriever"))
        XCTAssertFalse(BreedLabelMapper.isCatBreed("toaster"))
        XCTAssertFalse(BreedLabelMapper.isCatBreed(""))
        XCTAssertFalse(BreedLabelMapper.isCatBreed("tabby"))
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
        XCTAssertTrue(names.contains("Persian"))
        XCTAssertTrue(names.contains("Siamese"))
        XCTAssertTrue(names.contains("Maine Coon"))
        XCTAssertTrue(names.contains("Domestic Shorthair"))
        XCTAssertTrue(names.contains("Tabby"))
    }

    func test_allDisplayNames_matchesCatBreedCanonicalList() {
        let mapperNames = BreedLabelMapper.allDisplayNames
        let catBreedNames = CatBreed.allDisplayNames
        XCTAssertEqual(mapperNames, catBreedNames,
                       "BreedLabelMapper.allDisplayNames must equal CatBreed.allDisplayNames")
    }

    func test_allDisplayNames_isBroaderThanModelMapping() {
        let names = BreedLabelMapper.allDisplayNames
        XCTAssertGreaterThan(names.count, 12, "curated list should be larger than the 12 model labels")
    }
}
