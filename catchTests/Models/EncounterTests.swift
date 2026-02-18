import XCTest
import SwiftData

@MainActor
final class EncounterTests: XCTestCase {

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

    func test_encounterInitDefaults() {
        let before = Date()
        let encounter = Encounter()
        let after = Date()

        XCTAssertGreaterThanOrEqual(encounter.date, before)
        XCTAssertLessThanOrEqual(encounter.date, after)
        XCTAssertEqual(encounter.notes, "")
        XCTAssertNil(encounter.cat)
    }

    func test_encounterPersistence_insertAndFetch() throws {
        let encounter = Encounter(notes: "spotted by the dumpster again")
        context.insert(encounter)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Encounter>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.notes, "spotted by the dumpster again")
    }

    func test_encounterLinksTocat() throws {
        let cat = Fixtures.cat(name: "Potato", in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Encounter>()).first
        XCTAssertNotNil(fetched?.cat)
        XCTAssertEqual(fetched?.cat?.name, "Potato")
    }

    func test_encounterLocation_hasCoordinates() {
        let location = Location.make()
        let encounter = Encounter(location: location)
        XCTAssertTrue(encounter.location.hasCoordinates)
        XCTAssertEqual(encounter.location.name, "Back Alley")
    }

    func test_encounterLocation_emptyByDefault() {
        let encounter = Encounter()
        XCTAssertFalse(encounter.location.hasCoordinates)
        XCTAssertEqual(encounter.location.name, "")
    }

    func test_multipleEncountersForOneCat() throws {
        let cat = Fixtures.cat(name: "Regulars", in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Encounter>())
        XCTAssertEqual(fetched.count, 3)
        XCTAssertTrue(fetched.allSatisfy { $0.cat?.name == "Regulars" })
    }
}
