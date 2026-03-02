import XCTest

final class BreedLogSortOptionTests: XCTestCase {

    // MARK: - Test Data

    private func makeEntry(
        name: String,
        rarity: BreedRarity,
        isDiscovered: Bool = true
    ) -> BreedLogEntry {
        let catalog = BreedCatalogEntry(
            id: name,
            displayName: name,
            description: "",
            funFact: "",
            rarity: rarity,
            icon: "cat"
        )
        return BreedLogEntry(
            catalogEntry: catalog,
            isDiscovered: isDiscovered,
            catCount: isDiscovered ? 1 : 0,
            firstDiscoveredDate: isDiscovered ? Date() : nil,
            previewPhotoData: nil
        )
    }

    private var sampleEntries: [BreedLogEntry] {
        [
            makeEntry(name: "Bengal", rarity: .rare),
            makeEntry(name: "Tabby", rarity: .common),
            makeEntry(name: "Sphynx", rarity: .legendary),
            makeEntry(name: "Abyssinian", rarity: .uncommon),
        ]
    }

    // MARK: - Default Direction

    func test_defaultDirection_rarityIsDescending() {
        XCTAssertEqual(BreedLogSortOption.rarity.defaultDirection, .descending)
    }

    func test_defaultDirection_alphabeticalIsAscending() {
        XCTAssertEqual(BreedLogSortOption.alphabetical.defaultDirection, .ascending)
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
        XCTAssertEqual(names, ["Sphynx", "Bengal", "Abyssinian", "Tabby"])
    }

    func test_rarity_ascending_leastRareFirst() {
        let result = BreedLogSortOption.rarity.sorted(sampleEntries, direction: .ascending)
        let names = result.map(\.catalogEntry.displayName)
        XCTAssertEqual(names, ["Tabby", "Abyssinian", "Bengal", "Sphynx"])
    }

    // MARK: - Alphabetical Sort

    func test_alphabetical_ascending_aToZ() {
        let result = BreedLogSortOption.alphabetical.sorted(sampleEntries, direction: .ascending)
        let names = result.map(\.catalogEntry.displayName)
        XCTAssertEqual(names, ["Abyssinian", "Bengal", "Sphynx", "Tabby"])
    }

    func test_alphabetical_descending_zToA() {
        let result = BreedLogSortOption.alphabetical.sorted(sampleEntries, direction: .descending)
        let names = result.map(\.catalogEntry.displayName)
        XCTAssertEqual(names, ["Tabby", "Sphynx", "Bengal", "Abyssinian"])
    }

    // MARK: - Discovered First Sort

    func test_discoveredFirst_descending_discoveredOnTop() {
        let entries = [
            makeEntry(name: "Bengal", rarity: .rare, isDiscovered: true),
            makeEntry(name: "Sphynx", rarity: .legendary, isDiscovered: false),
            makeEntry(name: "Abyssinian", rarity: .uncommon, isDiscovered: true),
            makeEntry(name: "Tabby", rarity: .common, isDiscovered: false),
        ]

        let result = BreedLogSortOption.discoveredFirst.sorted(entries, direction: .descending)
        let names = result.map(\.catalogEntry.displayName)

        // Discovered first (alphabetically within group), then undiscovered (alphabetically)
        XCTAssertEqual(names, ["Abyssinian", "Bengal", "Sphynx", "Tabby"])
    }

    func test_discoveredFirst_ascending_undiscoveredOnTop() {
        let entries = [
            makeEntry(name: "Bengal", rarity: .rare, isDiscovered: true),
            makeEntry(name: "Sphynx", rarity: .legendary, isDiscovered: false),
            makeEntry(name: "Abyssinian", rarity: .uncommon, isDiscovered: true),
            makeEntry(name: "Tabby", rarity: .common, isDiscovered: false),
        ]

        let result = BreedLogSortOption.discoveredFirst.sorted(entries, direction: .ascending)
        let names = result.map(\.catalogEntry.displayName)

        // Undiscovered first (alphabetically within group), then discovered (alphabetically)
        XCTAssertEqual(names, ["Sphynx", "Tabby", "Abyssinian", "Bengal"])
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
        let single = [makeEntry(name: "Bengal", rarity: .rare)]
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