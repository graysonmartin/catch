import XCTest
import CatchCore

final class BreedLogSortOptionTests: XCTestCase {

    // MARK: - Test Data

    private func makeEntry(
        breed: CatBreed,
        isDiscovered: Bool = true
    ) -> BreedLogEntry {
        guard let catalogEntry = BreedCatalog.entry(for: breed) else {
            fatalError("No catalog entry for breed \(breed.displayName)")
        }
        return BreedLogEntry(
            catalogEntry: catalogEntry,
            isDiscovered: isDiscovered,
            catCount: isDiscovered ? 1 : 0,
            firstDiscoveredDate: isDiscovered ? Date() : nil,
            previewPhotoUrl: nil
        )
    }

    /// Four breeds spanning all rarity tiers: common, uncommon, rare, legendary.
    private var sampleEntries: [BreedLogEntry] {
        [
            makeEntry(breed: .bengal),          // rare
            makeEntry(breed: .siamese),          // common
            makeEntry(breed: .sphynx),           // legendary
            makeEntry(breed: .abyssinian),       // uncommon
        ]
    }

    // MARK: - Default Direction

    func test_defaultDirection_rarityIsAscending() {
        XCTAssertEqual(BreedLogSortOption.rarity.defaultDirection, .ascending)
    }

    func test_defaultDirection_discoveredFirstIsDescending() {
        XCTAssertEqual(BreedLogSortOption.discoveredFirst.defaultDirection, .descending)
    }

    // MARK: - Sort Direction Toggle

    func test_toggled_ascendingBecomesDescending() {
        XCTAssertEqual(BreedLogSortDirection.ascending.toggled, .descending)
    }

    func test_toggled_descendingBecomesAscending() {
        XCTAssertEqual(BreedLogSortDirection.descending.toggled, .ascending)
    }

    // MARK: - Chevron Symbol

    func test_chevronSymbol_ascending() {
        XCTAssertEqual(BreedLogSortDirection.ascending.chevronSymbol, "chevron.up")
    }

    func test_chevronSymbol_descending() {
        XCTAssertEqual(BreedLogSortDirection.descending.chevronSymbol, "chevron.down")
    }

    // MARK: - Rarity Sort

    func test_rarity_descending_mostRareFirst() {
        let result = BreedLogSortOption.rarity.sorted(sampleEntries, direction: .descending)
        let names = result.map(\.catalogEntry.displayName)
        XCTAssertEqual(names, ["Sphynx", "Bengal", "Abyssinian", "Siamese"])
    }

    func test_rarity_ascending_leastRareFirst() {
        let result = BreedLogSortOption.rarity.sorted(sampleEntries, direction: .ascending)
        let names = result.map(\.catalogEntry.displayName)
        XCTAssertEqual(names, ["Siamese", "Abyssinian", "Bengal", "Sphynx"])
    }

    // MARK: - Discovered First Sort

    func test_discoveredFirst_descending_discoveredOnTop() {
        let entries = [
            makeEntry(breed: .bengal, isDiscovered: true),
            makeEntry(breed: .sphynx, isDiscovered: false),
            makeEntry(breed: .abyssinian, isDiscovered: true),
            makeEntry(breed: .siamese, isDiscovered: false),
        ]

        let result = BreedLogSortOption.discoveredFirst.sorted(entries, direction: .descending)
        let names = result.map(\.catalogEntry.displayName)

        // Discovered first (alphabetically within group), then undiscovered (alphabetically)
        XCTAssertEqual(names, ["Abyssinian", "Bengal", "Siamese", "Sphynx"])
    }

    func test_discoveredFirst_ascending_undiscoveredOnTop() {
        let entries = [
            makeEntry(breed: .bengal, isDiscovered: true),
            makeEntry(breed: .sphynx, isDiscovered: false),
            makeEntry(breed: .abyssinian, isDiscovered: true),
            makeEntry(breed: .siamese, isDiscovered: false),
        ]

        let result = BreedLogSortOption.discoveredFirst.sorted(entries, direction: .ascending)
        let names = result.map(\.catalogEntry.displayName)

        // Undiscovered first (alphabetically within group), then discovered (alphabetically)
        XCTAssertEqual(names, ["Siamese", "Sphynx", "Abyssinian", "Bengal"])
    }

    // MARK: - Empty Input

    func test_sort_emptyArray_returnsEmpty() {
        let empty: [BreedLogEntry] = []
        for option in BreedLogSortOption.allCases {
            XCTAssertTrue(option.sorted(empty, direction: .ascending).isEmpty)
            XCTAssertTrue(option.sorted(empty, direction: .descending).isEmpty)
        }
    }

    // MARK: - Single Element

    func test_sort_singleElement_returnsSame() {
        let single = [makeEntry(breed: .bengal)]
        for option in BreedLogSortOption.allCases {
            let asc = option.sorted(single, direction: .ascending)
            let desc = option.sorted(single, direction: .descending)
            XCTAssertEqual(asc.count, 1)
            XCTAssertEqual(desc.count, 1)
            XCTAssertEqual(asc.first?.id, "Bengal")
            XCTAssertEqual(desc.first?.id, "Bengal")
        }
    }
}
