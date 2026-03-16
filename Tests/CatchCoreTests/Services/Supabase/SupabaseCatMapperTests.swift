import XCTest
@testable import CatchCore

final class SupabaseCatMapperTests: XCTestCase {

    // MARK: - toCloudCat

    func testMapsIDToRecordName() {
        let id = UUID()
        let cat = SupabaseCat.fixture(id: id)

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertEqual(result.recordName, id.uuidString)
    }

    func testMapsOwnerID() {
        let ownerID = UUID()
        let cat = SupabaseCat.fixture(ownerID: ownerID)

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertEqual(result.ownerID, ownerID.uuidString)
    }

    func testMapsNameAndBreed() {
        let cat = SupabaseCat.fixture(name: "whiskers", breed: "tabby")

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertEqual(result.name, "whiskers")
        XCTAssertEqual(result.breed, "tabby")
    }

    func testEmptyNameMapsToNil() {
        let cat = SupabaseCat.fixture(name: "")

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertNil(result.name)
    }

    func testMapsLocationFields() {
        let cat = SupabaseCat.fixture(
            locationName: "park bench",
            locationLat: 37.7749,
            locationLng: -122.4194
        )

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertEqual(result.locationName, "park bench")
        XCTAssertEqual(result.locationLatitude, 37.7749)
        XCTAssertEqual(result.locationLongitude, -122.4194)
    }

    func testMapsNilOptionalFieldsToEmptyStrings() {
        let cat = SupabaseCat.fixture(
            breed: nil,
            estimatedAge: nil,
            locationName: nil,
            notes: nil
        )

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertEqual(result.breed, "")
        XCTAssertEqual(result.estimatedAge, "")
        XCTAssertEqual(result.locationName, "")
        XCTAssertEqual(result.notes, "")
    }

    func testMapsIsOwned() {
        let ownedCat = SupabaseCat.fixture(isOwned: true)
        let stray = SupabaseCat.fixture(isOwned: false)

        XCTAssertTrue(SupabaseCatMapper.toCloudCat(ownedCat).isOwned)
        XCTAssertFalse(SupabaseCatMapper.toCloudCat(stray).isOwned)
    }

    func testPhotosAlwaysEmpty() {
        let cat = SupabaseCat.fixture(photoUrls: ["url1", "url2"])

        let result = SupabaseCatMapper.toCloudCat(cat)

        XCTAssertTrue(result.photos.isEmpty)
    }

    // MARK: - insertPayload

    func testInsertPayloadMapsFields() {
        let payload = CatSyncPayload(
            recordName: nil,
            name: "mittens",
            breed: "persian",
            estimatedAge: "5 years",
            locationName: "rooftop",
            locationLatitude: 40.7128,
            locationLongitude: -74.0060,
            notes: "fluffy",
            isOwned: true,
            createdAt: Date(timeIntervalSince1970: 1000),
            photos: []
        )

        let result = SupabaseCatMapper.insertPayload(from: payload, ownerID: "owner-1", recordName: "cat-1")

        XCTAssertEqual(result.id, "cat-1")
        XCTAssertEqual(result.ownerID, "owner-1")
        XCTAssertEqual(result.name, "mittens")
        XCTAssertEqual(result.breed, "persian")
        XCTAssertEqual(result.estimatedAge, "5 years")
        XCTAssertEqual(result.locationName, "rooftop")
        XCTAssertEqual(result.locationLat, 40.7128)
        XCTAssertEqual(result.locationLng, -74.0060)
        XCTAssertEqual(result.notes, "fluffy")
        XCTAssertTrue(result.isOwned)
    }

    func testInsertPayloadConvertsEmptyStringsToNil() {
        let payload = CatSyncPayload(
            recordName: nil,
            name: nil,
            breed: nil,
            estimatedAge: "",
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )

        let result = SupabaseCatMapper.insertPayload(from: payload, ownerID: "o", recordName: "c")

        XCTAssertEqual(result.name, "")
        XCTAssertNil(result.estimatedAge)
        XCTAssertNil(result.locationName)
        XCTAssertNil(result.notes)
    }

    // MARK: - updatePayload

    func testUpdatePayloadMapsFields() {
        let payload = CatSyncPayload(
            recordName: "existing",
            name: "updated name",
            breed: "tabby",
            estimatedAge: "1 year",
            locationName: "garden",
            locationLatitude: 51.5074,
            locationLongitude: -0.1278,
            notes: "moved",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )

        let result = SupabaseCatMapper.updatePayload(from: payload)

        XCTAssertEqual(result.name, "updated name")
        XCTAssertEqual(result.breed, "tabby")
        XCTAssertEqual(result.estimatedAge, "1 year")
        XCTAssertEqual(result.locationName, "garden")
        XCTAssertEqual(result.locationLat, 51.5074)
        XCTAssertEqual(result.locationLng, -0.1278)
        XCTAssertEqual(result.notes, "moved")
        XCTAssertFalse(result.isOwned)
    }
}
