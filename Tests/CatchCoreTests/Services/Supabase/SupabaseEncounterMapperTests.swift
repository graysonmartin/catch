import XCTest
@testable import CatchCore

final class SupabaseEncounterMapperTests: XCTestCase {

    // MARK: - toCloudEncounter

    func testMapsIDToRecordName() {
        let id = UUID()
        let encounter = SupabaseEncounter.fixture(id: id)

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertEqual(result.recordName, id.uuidString.lowercased())
    }

    func testMapsOwnerID() {
        let ownerID = UUID()
        let encounter = SupabaseEncounter.fixture(ownerID: ownerID)

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertEqual(result.ownerID, ownerID.uuidString.lowercased())
    }

    func testMapsCatIDToCatRecordName() {
        let catID = UUID()
        let encounter = SupabaseEncounter.fixture(catID: catID)

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertEqual(result.catRecordName, catID.uuidString.lowercased())
    }

    func testMapsDateAndLocation() {
        let date = Date(timeIntervalSince1970: 1000)
        let encounter = SupabaseEncounter.fixture(
            date: date,
            locationName: "alley",
            locationLat: 37.7749,
            locationLng: -122.4194
        )

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.locationName, "alley")
        XCTAssertEqual(result.locationLatitude, 37.7749)
        XCTAssertEqual(result.locationLongitude, -122.4194)
    }

    func testMapsNilOptionalFieldsToEmptyStrings() {
        let encounter = SupabaseEncounter.fixture(
            locationName: nil,
            notes: nil
        )

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertEqual(result.locationName, "")
        XCTAssertEqual(result.notes, "")
    }

    func testPhotosDataAlwaysEmpty() {
        let encounter = SupabaseEncounter.fixture(photoUrls: ["url1", "url2"])

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertTrue(result.photos.isEmpty)
    }

    func testPhotoUrlsPassedThrough() {
        let encounter = SupabaseEncounter.fixture(photoUrls: ["url1", "url2"])

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertEqual(result.photoUrls, ["url1", "url2"])
    }

    func testEmptyPhotoUrlsPassedThrough() {
        let encounter = SupabaseEncounter.fixture(photoUrls: [])

        let result = SupabaseEncounterMapper.toCloudEncounter(encounter)

        XCTAssertTrue(result.photoUrls.isEmpty)
    }

    // MARK: - insertPayload

    func testInsertPayloadMapsFields() {
        let date = Date(timeIntervalSince1970: 2000)
        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-1",
            date: date,
            locationName: "park",
            locationLatitude: 40.7128,
            locationLongitude: -74.0060,
            notes: "spotted napping",
            photos: []
        )

        let result = SupabaseEncounterMapper.insertPayload(
            from: payload,
            ownerID: "owner-1",
            recordName: "enc-1"
        )

        XCTAssertEqual(result.id, "enc-1")
        XCTAssertEqual(result.ownerID, "owner-1")
        XCTAssertEqual(result.catID, "cat-1")
        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.locationName, "park")
        XCTAssertEqual(result.locationLat, 40.7128)
        XCTAssertEqual(result.locationLng, -74.0060)
        XCTAssertEqual(result.notes, "spotted napping")
    }

    func testInsertPayloadConvertsEmptyStringsToNil() {
        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-1",
            date: Date(),
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )

        let result = SupabaseEncounterMapper.insertPayload(
            from: payload,
            ownerID: "o",
            recordName: "e"
        )

        XCTAssertNil(result.locationName)
        XCTAssertNil(result.notes)
    }

    // MARK: - updatePayload

    func testUpdatePayloadMapsFields() {
        let date = Date(timeIntervalSince1970: 3000)
        let payload = EncounterSyncPayload(
            recordName: "existing",
            catRecordName: "cat-1",
            date: date,
            locationName: "garden",
            locationLatitude: 51.5074,
            locationLongitude: -0.1278,
            notes: "updated notes",
            photos: []
        )

        let result = SupabaseEncounterMapper.updatePayload(from: payload)

        XCTAssertEqual(result.date, date)
        XCTAssertEqual(result.locationName, "garden")
        XCTAssertEqual(result.locationLat, 51.5074)
        XCTAssertEqual(result.locationLng, -0.1278)
        XCTAssertEqual(result.notes, "updated notes")
    }
}
