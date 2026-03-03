import XCTest
import SwiftData
import CatchCore

@MainActor
final class ProfileDiaryTabTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer.forTesting()
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
    }

    // MARK: - Date grouping

    func testEncountersOnSameDayGroupTogether() throws {
        let cat = Fixtures.cat(name: "Mochi", in: context)
        let today = Calendar.current.startOfDay(for: Date())
        let morning = today.addingTimeInterval(3600 * 9)
        let afternoon = today.addingTimeInterval(3600 * 14)

        _ = Fixtures.encounter(for: cat, date: morning, in: context)
        _ = Fixtures.encounter(for: cat, date: afternoon, in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let grouped = groupEncountersByDay(encounters)

        XCTAssertEqual(grouped.count, 1, "Both encounters should be in the same day group")
        XCTAssertEqual(grouped[0].encounters.count, 2)
    }

    func testEncountersOnDifferentDaysGroupSeparately() throws {
        let cat = Fixtures.cat(name: "Luna", in: context)
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        _ = Fixtures.encounter(for: cat, date: today, in: context)
        _ = Fixtures.encounter(for: cat, date: yesterday, in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let grouped = groupEncountersByDay(encounters)

        XCTAssertEqual(grouped.count, 2, "Encounters on different days should be in separate groups")
    }

    func testGroupsAreSortedNewestFirst() throws {
        let cat = Fixtures.cat(name: "Biscuit", in: context)
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        _ = Fixtures.encounter(for: cat, date: lastWeek, in: context)
        _ = Fixtures.encounter(for: cat, date: today, in: context)
        _ = Fixtures.encounter(for: cat, date: threeDaysAgo, in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let grouped = groupEncountersByDay(encounters)

        XCTAssertEqual(grouped.count, 3)
        XCTAssertTrue(grouped[0].date > grouped[1].date)
        XCTAssertTrue(grouped[1].date > grouped[2].date)
    }

    // MARK: - Date formatting

    func testDateHeaderForCurrentYear() {
        let components = DateComponents(year: Calendar.current.component(.year, from: Date()), month: 2, day: 25)
        let date = Calendar.current.date(from: components)!
        let header = formattedDateHeader(date)

        XCTAssertEqual(header, header.lowercased(), "Date header should be lowercase")
        XCTAssertFalse(header.contains("\(Calendar.current.component(.year, from: Date()))"),
                       "Current year should not appear in header")
    }

    func testDateHeaderForPreviousYear() {
        let components = DateComponents(year: 2024, month: 12, day: 14)
        let date = Calendar.current.date(from: components)!
        let header = formattedDateHeader(date)

        XCTAssertEqual(header, header.lowercased(), "Date header should be lowercase")
        XCTAssertTrue(header.contains("2024"), "Previous year should appear in header")
    }

    // MARK: - Search filtering

    func testSearchFiltersByCatName() throws {
        let mochi = Fixtures.cat(name: "Mochi", in: context)
        let luna = Fixtures.cat(name: "Luna", in: context)

        _ = Fixtures.encounter(for: mochi, in: context)
        _ = Fixtures.encounter(for: luna, in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let filtered = filterEncounters(encounters, searchText: "mochi")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].cat?.name, "Mochi")
    }

    func testSearchFiltersByNotes() throws {
        let cat = Fixtures.cat(name: "Biscuit", in: context)
        _ = Fixtures.encounter(for: cat, notes: "spotted near the park", in: context)
        _ = Fixtures.encounter(for: cat, notes: "chilling on a car", in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let filtered = filterEncounters(encounters, searchText: "park")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered[0].notes.contains("park"))
    }

    func testSearchFiltersByLocation() throws {
        let cat = Fixtures.cat(name: "Shadow", in: context)
        _ = Fixtures.encounter(for: cat, location: Location(name: "Central Park"), in: context)
        _ = Fixtures.encounter(for: cat, location: Location(name: "Back Alley"), in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let filtered = filterEncounters(encounters, searchText: "central")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].location.name, "Central Park")
    }

    func testEmptySearchReturnsAll() throws {
        let cat = Fixtures.cat(name: "Bean", in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        _ = Fixtures.encounter(for: cat, in: context)

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let filtered = filterEncounters(encounters, searchText: "")

        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - First encounter detection

    func testEarliestEncounterIDsForMultipleCats() throws {
        let mochi = Fixtures.cat(name: "Mochi", in: context)
        let luna = Fixtures.cat(name: "Luna", in: context)

        let mochiFirst = Fixtures.encounter(
            for: mochi,
            date: Date().addingTimeInterval(-3600),
            in: context
        )
        let mochiSecond = Fixtures.encounter(
            for: mochi,
            date: Date(),
            in: context
        )
        let lunaFirst = Fixtures.encounter(
            for: luna,
            date: Date().addingTimeInterval(-7200),
            in: context
        )

        let encounters = try context.fetch(FetchDescriptor<Encounter>())
        let firstIDs = earliestEncounterIDs(encounters)

        XCTAssertTrue(firstIDs.contains(mochiFirst.persistentModelID))
        XCTAssertFalse(firstIDs.contains(mochiSecond.persistentModelID))
        XCTAssertTrue(firstIDs.contains(lunaFirst.persistentModelID))
    }

    // MARK: - Engagement count lookup

    func testLikeCountReturnsZeroForNilRecordName() {
        let count = lookupLikeCount(for: nil, likeCounts: ["enc1": 5])
        XCTAssertEqual(count, 0)
    }

    func testLikeCountReturnsValueForKnownRecordName() {
        let count = lookupLikeCount(for: "enc1", likeCounts: ["enc1": 5, "enc2": 3])
        XCTAssertEqual(count, 5)
    }

    func testLikeCountReturnsZeroForUnknownRecordName() {
        let count = lookupLikeCount(for: "enc99", likeCounts: ["enc1": 5])
        XCTAssertEqual(count, 0)
    }

    func testCommentCountReturnsZeroForNilRecordName() {
        let count = lookupCommentCount(for: nil, commentCounts: ["enc1": 2])
        XCTAssertEqual(count, 0)
    }

    func testCommentCountReturnsValueForKnownRecordName() {
        let count = lookupCommentCount(for: "enc1", commentCounts: ["enc1": 2])
        XCTAssertEqual(count, 2)
    }

    // MARK: - Engagement indicator visibility

    func testEngagementIsVisibleWhenLikeCountAboveZero() {
        XCTAssertTrue(hasEngagement(likeCount: 3, commentCount: 0))
    }

    func testEngagementIsVisibleWhenCommentCountAboveZero() {
        XCTAssertTrue(hasEngagement(likeCount: 0, commentCount: 1))
    }

    func testEngagementIsHiddenWhenBothCountsZero() {
        XCTAssertFalse(hasEngagement(likeCount: 0, commentCount: 0))
    }

    func testEngagementIsVisibleWhenBothCountsAboveZero() {
        XCTAssertTrue(hasEngagement(likeCount: 2, commentCount: 4))
    }

    // MARK: - Helpers (mirror ProfileDiaryTab logic)

    private func groupEncountersByDay(_ encounters: [Encounter]) -> [(date: Date, encounters: [Encounter])] {
        let grouped = Dictionary(grouping: encounters) { encounter in
            Calendar.current.startOfDay(for: encounter.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, encounters: $0.value.sorted { $0.date > $1.date }) }
    }

    private func filterEncounters(_ encounters: [Encounter], searchText: String) -> [Encounter] {
        guard !searchText.isEmpty else { return encounters }
        return encounters.filter { encounter in
            encounter.cat?.displayName.localizedCaseInsensitiveContains(searchText) == true
            || encounter.notes.localizedCaseInsensitiveContains(searchText)
            || encounter.location.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func formattedDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day()).lowercased()
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day().year()).lowercased()
        }
    }

    private func earliestEncounterIDs(_ encounters: [Encounter]) -> Set<PersistentIdentifier> {
        var ids = Set<PersistentIdentifier>()
        var seenCats = Set<PersistentIdentifier>()
        let allSorted = encounters.sorted { $0.date < $1.date }
        for encounter in allSorted {
            if let catID = encounter.cat?.persistentModelID, !seenCats.contains(catID) {
                seenCats.insert(catID)
                ids.insert(encounter.persistentModelID)
            }
        }
        return ids
    }

    private func lookupLikeCount(for recordName: String?, likeCounts: [String: Int]) -> Int {
        guard let recordName else { return 0 }
        return likeCounts[recordName, default: 0]
    }

    private func lookupCommentCount(for recordName: String?, commentCounts: [String: Int]) -> Int {
        guard let recordName else { return 0 }
        return commentCounts[recordName, default: 0]
    }

    private func hasEngagement(likeCount: Int, commentCount: Int) -> Bool {
        likeCount > 0 || commentCount > 0
    }
}
