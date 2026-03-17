import XCTest
import CatchCore

@MainActor
final class EncounterTests: XCTestCase {

    func test_encounterInitDefaults() {
        let before = Date()
        let encounter = Encounter()
        let after = Date()

        XCTAssertGreaterThanOrEqual(encounter.date, before)
        XCTAssertLessThanOrEqual(encounter.date, after)
        XCTAssertEqual(encounter.notes, "")
        XCTAssertNil(encounter.catID)
        XCTAssertTrue(encounter.photoUrls.isEmpty)
    }

    func test_encounterWithCat() {
        let cat = Fixtures.cat(name: "Potato")
        let encounter = Fixtures.encounter(for: cat, notes: "spotted by the dumpster again")

        XCTAssertEqual(encounter.catID, cat.id)
        XCTAssertEqual(encounter.notes, "spotted by the dumpster again")
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

    func test_encounterPhotoUrls_canBeSet() {
        let cat = Fixtures.cat()
        let encounter = Fixtures.encounter(for: cat, photoUrls: ["url1", "url2"])
        XCTAssertEqual(encounter.photoUrls.count, 2)
        XCTAssertEqual(encounter.photoUrls[0], "url1")
    }

    func test_encounterPhotoUrls_defaultsToEmpty() {
        let encounter = Encounter()
        XCTAssertEqual(encounter.photoUrls.count, 0)
    }

    // MARK: - Payload generation

    func test_toInsertPayload() {
        let catID = UUID()
        let encounter = Encounter(
            date: Date(),
            location: Location(name: "Park", latitude: 37.0, longitude: -122.0),
            notes: "test",
            catID: catID,
            photoUrls: ["url1"]
        )

        let payload = encounter.toInsertPayload(ownerID: "owner-123")
        XCTAssertEqual(payload.ownerID, "owner-123")
        XCTAssertEqual(payload.catID, catID.uuidString)
        XCTAssertEqual(payload.notes, "test")
        XCTAssertEqual(payload.photoUrls, ["url1"])
    }

    func test_toUpdatePayload() {
        let encounter = Encounter(
            date: Date(),
            location: Location(name: "Home", latitude: nil, longitude: nil),
            notes: "updated"
        )

        let payload = encounter.toUpdatePayload()
        XCTAssertEqual(payload.notes, "updated")
        XCTAssertNil(payload.locationLat)
    }
}
