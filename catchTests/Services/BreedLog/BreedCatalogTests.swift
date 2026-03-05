import XCTest
import CatchCore

final class BreedCatalogTests: XCTestCase {

    func test_catalogHas12Breeds() {
        XCTAssertEqual(BreedCatalog.count, 12)
        XCTAssertEqual(BreedCatalog.allBreeds.count, 12)
    }

    func test_catalogHasOneEntryPerCatBreed() {
        XCTAssertEqual(BreedCatalog.allBreeds.count, CatBreed.allCases.count)
    }

    func test_allIdsAreUnique() {
        let ids = BreedCatalog.allBreeds.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate breed IDs found")
    }

    func test_allDisplayNamesAreUnique() {
        let names = BreedCatalog.allBreeds.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count, "duplicate display names found")
    }

    func test_idsMatchCatBreedDisplayNames() {
        let catBreedNames = Set(CatBreed.allCases.map(\.displayName))
        let catalogIds = Set(BreedCatalog.allBreeds.map(\.id))
        XCTAssertEqual(catalogIds, catBreedNames, "catalog IDs must match CatBreed display names exactly")
    }

    func test_idsMatchBreedLabelMapperDisplayNames() {
        let mapperNames = Set(BreedLabelMapper.allDisplayNames)
        let catalogIds = Set(BreedCatalog.allBreeds.map(\.id))
        XCTAssertEqual(catalogIds, mapperNames, "catalog IDs must match BreedLabelMapper display names exactly")
    }

    func test_entryForKnownBreedReturnsEntry() {
        let entry = BreedCatalog.entry(for: "Domestic Shorthair")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.displayName, "Domestic Shorthair")
    }

    func test_entryForCatBreedReturnsEntry() {
        let entry = BreedCatalog.entry(for: .domesticShorthair)
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.displayName, "Domestic Shorthair")
        XCTAssertEqual(entry?.breed, .domesticShorthair)
    }

    func test_entryForUnknownBreedReturnsNil() {
        XCTAssertNil(BreedCatalog.entry(for: "Space Cat"))
        XCTAssertNil(BreedCatalog.entry(for: ""))
        XCTAssertNil(BreedCatalog.entry(for: "Tabby"))
    }

    func test_containsReturnsTrueForCatalogBreeds() {
        XCTAssertTrue(BreedCatalog.contains("Russian Blue"))
        XCTAssertTrue(BreedCatalog.contains("Bengal"))
        XCTAssertTrue(BreedCatalog.contains("Sphynx"))
    }

    func test_containsReturnsFalseForUnknownBreeds() {
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
}
