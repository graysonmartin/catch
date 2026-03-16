import XCTest
import CatchCore

@MainActor
final class ProfileDiaryTabTests: XCTestCase {

    // MARK: - Date grouping

    func testEncountersOnSameDayGroupTogether() {
        let cat = Fixtures.cat(name: "Mochi")
        let today = Calendar.current.startOfDay(for: Date())
        let morning = today.addingTimeInterval(3600 * 9)
        let afternoon = today.addingTimeInterval(3600 * 14)

        let encounters = [
            Fixtures.encounter(for: cat, date: morning),
            Fixtures.encounter(for: cat, date: afternoon)
        ]
        let grouped = groupEncountersByDay(encounters)

        XCTAssertEqual(grouped.count, 1, "Both encounters should be in the same day group")
        XCTAssertEqual(grouped[0].encounters.count, 2)
    }

    func testEncountersOnDifferentDaysGroupSeparately() {
        let cat = Fixtures.cat(name: "Luna")
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let encounters = [
            Fixtures.encounter(for: cat, date: today),
            Fixtures.encounter(for: cat, date: yesterday)
        ]
        let grouped = groupEncountersByDay(encounters)

        XCTAssertEqual(grouped.count, 2, "Encounters on different days should be in separate groups")
    }

    func testGroupsAreSortedNewestFirst() {
        let cat = Fixtures.cat(name: "Biscuit")
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let encounters = [
            Fixtures.encounter(for: cat, date: lastWeek),
            Fixtures.encounter(for: cat, date: today),
            Fixtures.encounter(for: cat, date: threeDaysAgo)
        ]
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

    func testSearchFiltersByCatName() {
        let mochi = Fixtures.cat(name: "Mochi")
        let luna = Fixtures.cat(name: "Luna")

        let encounters = [
            Fixtures.encounter(for: mochi),
            Fixtures.encounter(for: luna)
        ]
        let filtered = filterEncounters(encounters, searchText: "mochi")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].cat?.name, "Mochi")
    }

    func testSearchFiltersByNotes() {
        let cat = Fixtures.cat(name: "Biscuit")
        let encounters = [
            Fixtures.encounter(for: cat, notes: "spotted near the park"),
            Fixtures.encounter(for: cat, notes: "chilling on a car")
        ]
        let filtered = filterEncounters(encounters, searchText: "park")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertTrue(filtered[0].notes.contains("park"))
    }

    func testSearchFiltersByLocation() {
        let cat = Fixtures.cat(name: "Shadow")
        let encounters = [
            Fixtures.encounter(for: cat, location: Location(name: "Central Park")),
            Fixtures.encounter(for: cat, location: Location(name: "Back Alley"))
        ]
        let filtered = filterEncounters(encounters, searchText: "central")

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].location.name, "Central Park")
    }

    func testEmptySearchReturnsAll() {
        let cat = Fixtures.cat(name: "Bean")
        let encounters = [
            Fixtures.encounter(for: cat),
            Fixtures.encounter(for: cat)
        ]
        let filtered = filterEncounters(encounters, searchText: "")

        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - First encounter detection

    func testEarliestEncounterIDsForMultipleCats() {
        let mochi = Fixtures.cat(name: "Mochi")
        let luna = Fixtures.cat(name: "Luna")

        let mochiFirst = Fixtures.encounter(for: mochi, date: Date().addingTimeInterval(-3600))
        let mochiSecond = Fixtures.encounter(for: mochi, date: Date())
        let lunaFirst = Fixtures.encounter(for: luna, date: Date().addingTimeInterval(-7200))

        let encounters = [mochiFirst, mochiSecond, lunaFirst]
        let firstIDs = earliestEncounterIDs(encounters)

        XCTAssertTrue(firstIDs.contains(mochiFirst.id))
        XCTAssertFalse(firstIDs.contains(mochiSecond.id))
        XCTAssertTrue(firstIDs.contains(lunaFirst.id))
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

    private func earliestEncounterIDs(_ encounters: [Encounter]) -> Set<UUID> {
        var ids = Set<UUID>()
        var seenCats = Set<UUID>()
        let allSorted = encounters.sorted { $0.date < $1.date }
        for encounter in allSorted {
            if let catID = encounter.catID, !seenCats.contains(catID) {
                seenCats.insert(catID)
                ids.insert(encounter.id)
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
