import XCTest
import CatchCore

final class BreedCatalogTests: XCTestCase {

    func test_catalogHas27Breeds() {
        XCTAssertEqual(BreedCatalog.count, 27)
        XCTAssertEqual(BreedCatalog.allBreeds.count, 27)
    }

    func test_allIdsAreUnique() {
        let ids = BreedCatalog.allBreeds.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate breed IDs found")
    }

    func test_allDisplayNamesAreUnique() {
        let names = BreedCatalog.allBreeds.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count, "duplicate display names found")
    }

    func test_idsMatchBreedLabelMapperDisplayNames() {
        let mapperNames = Set(BreedLabelMapper.allDisplayNames)
        let catalogIds = Set(BreedCatalog.allBreeds.map(\.id))
        XCTAssertEqual(catalogIds, mapperNames, "catalog IDs must match BreedLabelMapper display names exactly")
    }

    func test_entryForKnownBreedReturnsEntry() {
        let entry = BreedCatalog.entry(for: "Tabby")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.displayName, "Tabby")
    }

    func test_entryForUnknownBreedReturnsNil() {
        XCTAssertNil(BreedCatalog.entry(for: "Space Cat"))
        XCTAssertNil(BreedCatalog.entry(for: ""))
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
