import XCTest
@testable import CatchCore

final class BreedCatalogCoreTests: XCTestCase {

    func test_catalogHas28Breeds() {
        XCTAssertEqual(BreedCatalog.count, 28)
        XCTAssertEqual(BreedCatalog.allBreeds.count, 28)
    }

    func test_catalogHasOneEntryPerCatBreed() {
        XCTAssertEqual(BreedCatalog.allBreeds.count, CatBreed.allCases.count)
    }

    func test_allIdsAreUnique() {
        let ids = BreedCatalog.allBreeds.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate breed IDs found")
    }

    func test_entryForDisplayName_knownBreedReturns() {
        let entry = BreedCatalog.entry(for: "Tabby")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.breed, .tabby)
    }

    func test_entryForDisplayName_unknownReturnsNil() {
        XCTAssertNil(BreedCatalog.entry(for: "Space Cat"))
        XCTAssertNil(BreedCatalog.entry(for: ""))
    }

    func test_entryForCatBreed_returnsMatchingEntry() {
        for breed in CatBreed.allCases {
            let entry = BreedCatalog.entry(for: breed)
            XCTAssertNotNil(entry, "\(breed.displayName) missing from catalog")
            XCTAssertEqual(entry?.breed, breed)
        }
    }

    func test_contains_trueForCatalogBreeds() {
        XCTAssertTrue(BreedCatalog.contains("Russian Blue"))
        XCTAssertTrue(BreedCatalog.contains("Bengal"))
        XCTAssertTrue(BreedCatalog.contains("Sphynx"))
    }

    func test_contains_falseForUnknownBreeds() {
        XCTAssertFalse(BreedCatalog.contains("Golden Retriever"))
        XCTAssertFalse(BreedCatalog.contains(""))
    }

    func test_allEntriesHaveNonEmptyFields() {
        for entry in BreedCatalog.allBreeds {
            XCTAssertFalse(entry.displayName.isEmpty, "\(entry.id) has empty displayName")
            XCTAssertFalse(entry.description.isEmpty, "\(entry.id) has empty description")
            XCTAssertFalse(entry.funFact.isEmpty, "\(entry.id) has empty funFact")
            XCTAssertFalse(entry.icon.isEmpty, "\(entry.id) has empty icon")
        }
    }

    func test_rarityDistribution() {
        let grouped = Dictionary(grouping: BreedCatalog.allBreeds, by: \.rarity)
        XCTAssertNotNil(grouped[.common])
        XCTAssertNotNil(grouped[.uncommon])
        XCTAssertNotNil(grouped[.rare])
        XCTAssertNotNil(grouped[.legendary])
    }

    func test_catalogIdsMatchBreedLabelMapperDisplayNames() {
        let mapperNames = Set(BreedLabelMapper.allDisplayNames)
        let catalogIds = Set(BreedCatalog.allBreeds.map(\.id))
        XCTAssertEqual(catalogIds, mapperNames)
    }

    func test_catalogIdsMatchCatBreedDisplayNames() {
        let catBreedNames = Set(CatBreed.allCases.map(\.displayName))
        let catalogIds = Set(BreedCatalog.allBreeds.map(\.id))
        XCTAssertEqual(catalogIds, catBreedNames)
    }
}
