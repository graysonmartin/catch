import XCTest
import SwiftData

@MainActor
final class CareEntryTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try ModelContainer.forTesting()
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    func test_durationDays_sameDay() {
        let now = Date()
        let entry = CareEntry(startDate: now, endDate: now)
        XCTAssertEqual(entry.durationDays, 0)
    }

    func test_durationDays_oneDay() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let entry = CareEntry(startDate: start, endDate: end)
        XCTAssertEqual(entry.durationDays, 1)
    }

    func test_durationDays_sevenDays() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let entry = CareEntry(startDate: start, endDate: end)
        XCTAssertEqual(entry.durationDays, 7)
    }

    func test_durationDays_persistedRoundtrip() throws {
        let cat = Fixtures.cat(in: context)
        let entry = Fixtures.careEntry(for: cat, durationDays: 5, in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CareEntry>()).first
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.durationDays, 5)
        _ = entry
    }

    func test_careEntry_defaultDatesAreNow() {
        let before = Date()
        let entry = CareEntry()
        let after = Date()
        XCTAssertGreaterThanOrEqual(entry.startDate, before)
        XCTAssertLessThanOrEqual(entry.startDate, after)
    }

    func test_careEntry_defaultNotesEmpty() {
        let entry = CareEntry()
        XCTAssertEqual(entry.notes, "")
    }

    func test_careEntry_notesPersistedCorrectly() throws {
        let cat = Fixtures.cat(in: context)
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 2, to: start)!
        let entry = CareEntry(startDate: start, endDate: end, notes: "fed twice daily", cat: cat)
        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CareEntry>()).first
        XCTAssertEqual(fetched?.notes, "fed twice daily")
    }

    func test_deleteCareEntry_removeFromStore() throws {
        let cat = Fixtures.cat(in: context)
        let entry = Fixtures.careEntry(for: cat, in: context)
        try context.save()

        context.delete(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CareEntry>())
        XCTAssertEqual(fetched.count, 0)
    }

    func test_deleteCareEntry_doesNotDeleteCat() throws {
        let cat = Fixtures.cat(name: "Keeper", in: context)
        let entry = Fixtures.careEntry(for: cat, in: context)
        try context.save()

        context.delete(entry)
        try context.save()

        let cats = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertEqual(cats.count, 1)
        XCTAssertEqual(cats.first?.name, "Keeper")
    }
}
