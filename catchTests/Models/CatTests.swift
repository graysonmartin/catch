import XCTest
import SwiftData

@MainActor
final class CatTests: XCTestCase {

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

    func test_catInitDefaults() {
        let cat = Cat(name: "Steven")
        XCTAssertEqual(cat.name, "Steven")
        XCTAssertNil(cat.breed)
        XCTAssertEqual(cat.estimatedAge, "")
        XCTAssertEqual(cat.notes, "")
        XCTAssertFalse(cat.isOwned)
        XCTAssertTrue(cat.photos.isEmpty)
        XCTAssertTrue(cat.encounters.isEmpty)
        XCTAssertTrue(cat.careEntries.isEmpty)
    }

    func test_catCreatedAtIsSetOnInit() {
        let before = Date()
        let cat = Cat(name: "Test")
        let after = Date()
        XCTAssertGreaterThanOrEqual(cat.createdAt, before)
        XCTAssertLessThanOrEqual(cat.createdAt, after)
    }

    func test_catPersistence_insertAndFetch() throws {
        context.insert(Cat(name: "Mango"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Mango")
    }

    func test_catPersistence_multipleInserts() throws {
        context.insert(Cat(name: "Mango"))
        context.insert(Cat(name: "Biscuit"))
        context.insert(Cat(name: "Noodle"))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertEqual(fetched.count, 3)
    }

    func test_catIsOwnedPersistedCorrectly() throws {
        context.insert(Cat(name: "Steven", isOwned: true))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>()).first
        XCTAssertEqual(fetched?.isOwned, true)
    }

    func test_catCascadeDeletesEncounters() throws {
        let cat = Fixtures.cat(name: "Doomed", in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Cat>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Encounter>()).count, 2)

        context.delete(try context.fetch(FetchDescriptor<Cat>())[0])
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Cat>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Encounter>()).count, 0)
    }

    func test_catCascadeDeletesCareEntries() throws {
        let cat = Fixtures.cat(name: "Doomed", in: context)
        _ = Fixtures.careEntry(for: cat, in: context)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Cat>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<CareEntry>()).count, 1)

        context.delete(try context.fetch(FetchDescriptor<Cat>())[0])
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Cat>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<CareEntry>()).count, 0)
    }

    // MARK: - breed

    func test_catBreed_defaultsToNil() {
        let cat = Cat(name: "Mystery")
        XCTAssertNil(cat.breed)
    }

    func test_catBreed_canBeSetAndPersisted() throws {
        let cat = Cat(name: "Fancy", breed: "Persian")
        context.insert(cat)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cat>())
        XCTAssertEqual(fetched.first?.breed, "Persian")
    }

    // MARK: - lastEncounterDate

    func test_lastEncounterDate_nilWhenNoEncounters() {
        let cat = Cat(name: "Lonely")
        XCTAssertNil(cat.lastEncounterDate)
    }

    func test_lastEncounterDate_returnsSingleEncounterDate() throws {
        let cat = Fixtures.cat(name: "Solo", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)
        try context.save()

        XCTAssertEqual(cat.lastEncounterDate, encounter.date)
    }

    func test_lastEncounterDate_returnsMostRecentDate() throws {
        let cat = Fixtures.cat(name: "Popular", in: context)

        let oldDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!

        let oldEncounter = Encounter(date: oldDate, cat: cat)
        context.insert(oldEncounter)

        let recentEncounter = Encounter(date: recentDate, cat: cat)
        context.insert(recentEncounter)

        try context.save()

        XCTAssertEqual(cat.lastEncounterDate, recentDate)
    }
}
