import XCTest
import CatchCore

@MainActor
final class CatTests: XCTestCase {

    func test_catInitDefaults() {
        let cat = Cat(name: "Steven")
        XCTAssertEqual(cat.name, "Steven")
        XCTAssertNil(cat.breed)
        XCTAssertEqual(cat.estimatedAge, "")
        XCTAssertEqual(cat.notes, "")
        XCTAssertFalse(cat.isOwned)
        XCTAssertTrue(cat.photoUrls.isEmpty)
        XCTAssertTrue(cat.encounters.isEmpty)
    }

    func test_catCreatedAtIsSetOnInit() {
        let before = Date()
        let cat = Cat(name: "Test")
        let after = Date()
        XCTAssertGreaterThanOrEqual(cat.createdAt, before)
        XCTAssertLessThanOrEqual(cat.createdAt, after)
    }

    // MARK: - breed

    func test_catBreed_defaultsToNil() {
        let cat = Cat(name: "Mystery")
        XCTAssertNil(cat.breed)
    }

    func test_catBreed_canBeSet() {
        let cat = Cat(name: "Fancy", breed: "Persian")
        XCTAssertEqual(cat.breed, "Persian")
    }

    // MARK: - lastEncounterDate

    func test_lastEncounterDate_nilWhenNoEncounters() {
        let cat = Cat(name: "Lonely")
        XCTAssertNil(cat.lastEncounterDate)
    }

    func test_lastEncounterDate_returnsSingleEncounterDate() {
        let cat = Fixtures.cat(name: "Solo")
        let encounter = Fixtures.encounter(for: cat)
        var catWithEnc = cat
        catWithEnc.encounters = [encounter]
        XCTAssertEqual(catWithEnc.lastEncounterDate, encounter.date)
    }

    func test_lastEncounterDate_returnsMostRecentDate() {
        let cat = Fixtures.cat(name: "Popular")

        let oldDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!

        let oldEncounter = Encounter(date: oldDate, catID: cat.id, ownerID: cat.ownerID)
        let recentEncounter = Encounter(date: recentDate, catID: cat.id, ownerID: cat.ownerID)

        var catWithEnc = cat
        catWithEnc.encounters = [oldEncounter, recentEncounter]

        XCTAssertEqual(catWithEnc.lastEncounterDate, recentDate)
    }

    // MARK: - displayName

    func test_displayName_returnsNameWhenSet() {
        let cat = Cat(name: "Mochi")
        XCTAssertEqual(cat.displayName, "Mochi")
    }

    func test_displayName_returnsFallbackWhenNil() {
        let cat = Cat()
        XCTAssertEqual(cat.displayName, CatchStrings.Common.unnamedCatFallback)
    }

    func test_displayName_returnsFallbackWhenEmpty() {
        let cat = Cat(name: "")
        XCTAssertEqual(cat.displayName, CatchStrings.Common.unnamedCatFallback)
    }

    // MARK: - isUnnamed

    func test_isUnnamed_trueWhenNilName() {
        let cat = Cat()
        XCTAssertTrue(cat.isUnnamed)
    }

    func test_isUnnamed_trueWhenEmptyName() {
        let cat = Cat(name: "")
        XCTAssertTrue(cat.isUnnamed)
    }

    func test_isUnnamed_falseWhenNamed() {
        let cat = Cat(name: "Mochi")
        XCTAssertFalse(cat.isUnnamed)
    }

    // MARK: - isSteven

    func test_isSteven_falseWhenNameIsNil() {
        let cat = Cat(breed: "Domestic Shorthair")
        XCTAssertFalse(cat.isSteven)
    }

    // MARK: - nil name behavior

    func test_nilNameCreatesUnnamedCat() {
        let cat = Cat()
        XCTAssertNil(cat.name)
        XCTAssertTrue(cat.isUnnamed)
    }

    func test_namedCatCanBeRenamed() {
        var cat = Cat(name: "Temp")
        cat.name = nil
        XCTAssertNil(cat.name)
        XCTAssertTrue(cat.isUnnamed)
    }

    func test_unnamedCatCanBeNamed() {
        var cat = Cat()
        cat.name = "Now Named"
        XCTAssertEqual(cat.name, "Now Named")
        XCTAssertFalse(cat.isUnnamed)
    }

    // MARK: - Payload generation

    func test_toInsertPayload_generatesCorrectPayload() {
        let cat = Cat(
            id: UUID(),
            name: "Test",
            breed: "Persian",
            location: Location(name: "Home", latitude: 37.0, longitude: -122.0),
            notes: "test notes",
            isOwned: true,
            photoUrls: ["url1", "url2"]
        )

        let payload = cat.toInsertPayload(ownerID: "owner-123")
        XCTAssertEqual(payload.id, cat.id.uuidString)
        XCTAssertEqual(payload.ownerID, "owner-123")
        XCTAssertEqual(payload.name, "Test")
        XCTAssertEqual(payload.breed, "Persian")
        XCTAssertEqual(payload.isOwned, true)
        XCTAssertEqual(payload.photoUrls, ["url1", "url2"])
    }
}
