import XCTest

final class CollectionSortFilterServiceTests: XCTestCase {

    private var service: DefaultCollectionSortFilterService!
    private let now = Date()

    override func setUp() {
        super.setUp()
        service = DefaultCollectionSortFilterService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeItem(
        id: String = UUID().uuidString,
        name: String = "Cat",
        isOwned: Bool = false,
        createdAt: Date? = nil,
        encounterCount: Int = 1,
        lastEncounterDate: Date? = nil
    ) -> CollectionCatItem {
        CollectionCatItem(
            id: id,
            name: name,
            isOwned: isOwned,
            createdAt: createdAt ?? now,
            encounterCount: encounterCount,
            lastEncounterDate: lastEncounterDate ?? now
        )
    }

    private func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
    }

    // MARK: - Sort: Most Recent

    func test_sort_mostRecent_ordersByLastEncounterDescending() {
        let old = makeItem(id: "old", name: "Old", lastEncounterDate: daysAgo(10))
        let recent = makeItem(id: "recent", name: "Recent", lastEncounterDate: daysAgo(1))
        let mid = makeItem(id: "mid", name: "Mid", lastEncounterDate: daysAgo(5))

        let result = service.sort([old, recent, mid], by: .mostRecent)
        XCTAssertEqual(result.map(\.id), ["recent", "mid", "old"])
    }

    func test_sort_mostRecent_nilDateGoesLast() {
        let noDate = CollectionCatItem(
            id: "none", name: "None", isOwned: false,
            createdAt: now, encounterCount: 0, lastEncounterDate: nil
        )
        let hasDate = makeItem(id: "has", name: "Has", lastEncounterDate: daysAgo(5))

        let result = service.sort([noDate, hasDate], by: .mostRecent)
        XCTAssertEqual(result.map(\.id), ["has", "none"])
    }

    // MARK: - Sort: Most Encounters

    func test_sort_mostEncounters_ordersByCountDescending() {
        let few = makeItem(id: "few", encounterCount: 2)
        let many = makeItem(id: "many", encounterCount: 10)
        let mid = makeItem(id: "mid", encounterCount: 5)

        let result = service.sort([few, many, mid], by: .mostEncounters)
        XCTAssertEqual(result.map(\.id), ["many", "mid", "few"])
    }

    // MARK: - Sort: Oldest First

    func test_sort_oldestFirst_ordersByLastEncounterAscending() {
        let old = makeItem(id: "old", lastEncounterDate: daysAgo(10))
        let recent = makeItem(id: "recent", lastEncounterDate: daysAgo(1))

        let result = service.sort([recent, old], by: .oldestFirst)
        XCTAssertEqual(result.map(\.id), ["old", "recent"])
    }

    // MARK: - Sort: Alphabetical

    func test_sort_alphabetical_ordersByNameAZ() {
        let b = makeItem(id: "b", name: "Biscuit")
        let a = makeItem(id: "a", name: "Apollo")
        let c = makeItem(id: "c", name: "Clover")

        let result = service.sort([b, a, c], by: .alphabetical)
        XCTAssertEqual(result.map(\.id), ["a", "b", "c"])
    }

    func test_sort_alphabetical_isCaseInsensitive() {
        let upper = makeItem(id: "upper", name: "Ziggy")
        let lower = makeItem(id: "lower", name: "apollo")

        let result = service.sort([upper, lower], by: .alphabetical)
        XCTAssertEqual(result.map(\.id), ["lower", "upper"])
    }

    // MARK: - Filter: Owned Only

    func test_filter_ownedOnly_keepsOnlyOwned() {
        let owned = makeItem(id: "owned", isOwned: true)
        let stray = makeItem(id: "stray", isOwned: false)

        let result = service.filter([owned, stray], by: [.ownedOnly], now: now)
        XCTAssertEqual(result.map(\.id), ["owned"])
    }

    // MARK: - Filter: Repeats

    func test_filter_repeats_keepsMoreThanOneEncounter() {
        let once = makeItem(id: "once", encounterCount: 1)
        let twice = makeItem(id: "twice", encounterCount: 2)
        let many = makeItem(id: "many", encounterCount: 5)

        let result = service.filter([once, twice, many], by: [.repeats], now: now)
        XCTAssertEqual(result.map(\.id), ["twice", "many"])
    }

    func test_filter_repeats_excludesZeroEncounters() {
        let zero = makeItem(id: "zero", encounterCount: 0)
        let result = service.filter([zero], by: [.repeats], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Filter: Seen Last 7 Days

    func test_filter_seenLast7Days_keepsRecent() {
        let recent = makeItem(id: "recent", lastEncounterDate: daysAgo(3))
        let old = makeItem(id: "old", lastEncounterDate: daysAgo(14))

        let result = service.filter([recent, old], by: [.seenLast7Days], now: now)
        XCTAssertEqual(result.map(\.id), ["recent"])
    }

    func test_filter_seenLast7Days_excludesExactly8DaysAgo() {
        let item = makeItem(id: "edge", lastEncounterDate: daysAgo(8))
        let result = service.filter([item], by: [.seenLast7Days], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func test_filter_seenLast7Days_includesExactly7DaysAgo() {
        let item = makeItem(id: "edge", lastEncounterDate: daysAgo(7))
        let result = service.filter([item], by: [.seenLast7Days], now: now)
        XCTAssertEqual(result.count, 1)
    }

    func test_filter_seenLast7Days_excludesNilDate() {
        let item = CollectionCatItem(
            id: "nil", name: "None", isOwned: false,
            createdAt: now, encounterCount: 0, lastEncounterDate: nil
        )
        let result = service.filter([item], by: [.seenLast7Days], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Filter: Seen Last 30 Days

    func test_filter_seenLast30Days_keepsRecent() {
        let recent = makeItem(id: "recent", lastEncounterDate: daysAgo(15))
        let old = makeItem(id: "old", lastEncounterDate: daysAgo(60))

        let result = service.filter([recent, old], by: [.seenLast30Days], now: now)
        XCTAssertEqual(result.map(\.id), ["recent"])
    }

    // MARK: - Multiple Filters Combined

    func test_filter_multipleFilters_appliedAsAND() {
        let ownedRecent = makeItem(id: "both", isOwned: true, encounterCount: 3, lastEncounterDate: daysAgo(2))
        let ownedOld = makeItem(id: "owned-old", isOwned: true, encounterCount: 3, lastEncounterDate: daysAgo(14))
        let strayRecent = makeItem(id: "stray-recent", isOwned: false, encounterCount: 3, lastEncounterDate: daysAgo(2))

        let result = service.filter(
            [ownedRecent, ownedOld, strayRecent],
            by: [.ownedOnly, .seenLast7Days],
            now: now
        )
        XCTAssertEqual(result.map(\.id), ["both"])
    }

    // MARK: - No Filters

    func test_filter_empty_returnsAll() {
        let a = makeItem(id: "a")
        let b = makeItem(id: "b")

        let result = service.filter([a, b], by: [], now: now)
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Apply (Sort + Filter Combined)

    func test_apply_filtersThenSorts() {
        let ownedA = makeItem(id: "a", name: "Apollo", isOwned: true, encounterCount: 2)
        let ownedZ = makeItem(id: "z", name: "Ziggy", isOwned: true, encounterCount: 2)
        let stray = makeItem(id: "s", name: "Stray", isOwned: false, encounterCount: 2)

        let result = service.apply(
            sort: .alphabetical,
            filters: [.ownedOnly],
            to: [ownedZ, stray, ownedA],
            now: now
        )
        XCTAssertEqual(result.map(\.id), ["a", "z"])
    }

    func test_apply_noFilters_justSorts() {
        let b = makeItem(id: "b", name: "Biscuit")
        let a = makeItem(id: "a", name: "Apollo")

        let result = service.apply(sort: .alphabetical, filters: [], to: [b, a], now: now)
        XCTAssertEqual(result.map(\.id), ["a", "b"])
    }

    func test_apply_allFilteredOut_returnsEmpty() {
        let stray = makeItem(id: "s", isOwned: false)
        let result = service.apply(sort: .mostRecent, filters: [.ownedOnly], to: [stray], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Edge Cases

    func test_sort_emptyInput_returnsEmpty() {
        let result = service.sort([], by: .alphabetical)
        XCTAssertTrue(result.isEmpty)
    }

    func test_filter_emptyInput_returnsEmpty() {
        let result = service.filter([], by: [.ownedOnly], now: now)
        XCTAssertTrue(result.isEmpty)
    }

    func test_sort_singleItem_returnsSameItem() {
        let item = makeItem(id: "solo")
        let result = service.sort([item], by: .mostRecent)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "solo")
    }
}
