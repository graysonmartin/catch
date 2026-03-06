import XCTest
@testable import CatchCore

final class CloudKitRestoreMapperTests: XCTestCase {

    // MARK: - mapCat

    func testMapCatConvertsAllFields() {
        let cloudCat = CloudCat(
            recordName: "cat-record-1",
            ownerID: "owner-1",
            name: "Steven",
            breed: "Domestic Shorthair",
            estimatedAge: "3 years",
            locationName: "Back porch",
            locationLatitude: 37.7749,
            locationLongitude: -122.4194,
            notes: "orange tabby, very chill",
            isOwned: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            photos: [Data([0x01, 0x02])]
        )

        let restored = CloudKitRestoreMapper.mapCat(cloudCat)

        XCTAssertEqual(restored.cloudKitRecordName, "cat-record-1")
        XCTAssertEqual(restored.name, "Steven")
        XCTAssertEqual(restored.breed, "Domestic Shorthair")
        XCTAssertEqual(restored.estimatedAge, "3 years")
        XCTAssertEqual(restored.location.name, "Back porch")
        XCTAssertEqual(restored.location.latitude, 37.7749)
        XCTAssertEqual(restored.location.longitude, -122.4194)
        XCTAssertEqual(restored.notes, "orange tabby, very chill")
        XCTAssertTrue(restored.isOwned)
        XCTAssertEqual(restored.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(restored.photos.count, 1)
    }

    func testMapCatHandlesNilNameAndCoordinates() {
        let cloudCat = CloudCat(
            recordName: "cat-2",
            ownerID: "owner-1",
            name: nil,
            breed: "",
            estimatedAge: "",
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )

        let restored = CloudKitRestoreMapper.mapCat(cloudCat)

        XCTAssertNil(restored.name)
        XCTAssertNil(restored.location.latitude)
        XCTAssertNil(restored.location.longitude)
        XCTAssertTrue(restored.photos.isEmpty)
    }

    // MARK: - mapEncounter

    func testMapEncounterConvertsAllFields() {
        let date = Date(timeIntervalSince1970: 1_700_100_000)
        let cloudEncounter = CloudEncounter(
            recordName: "enc-record-1",
            ownerID: "owner-1",
            catRecordName: "cat-record-1",
            date: date,
            locationName: "Park",
            locationLatitude: 40.7128,
            locationLongitude: -74.0060,
            notes: "spotted near the fountain",
            photos: [Data([0xAA, 0xBB])]
        )

        let restored = CloudKitRestoreMapper.mapEncounter(cloudEncounter)

        XCTAssertEqual(restored.cloudKitRecordName, "enc-record-1")
        XCTAssertEqual(restored.catRecordName, "cat-record-1")
        XCTAssertEqual(restored.date, date)
        XCTAssertEqual(restored.location.name, "Park")
        XCTAssertEqual(restored.location.latitude, 40.7128)
        XCTAssertEqual(restored.location.longitude, -74.0060)
        XCTAssertEqual(restored.notes, "spotted near the fountain")
        XCTAssertEqual(restored.photos.count, 1)
    }

    func testMapEncounterHandlesNilCoordinates() {
        let cloudEncounter = CloudEncounter(
            recordName: "enc-2",
            ownerID: "owner-1",
            catRecordName: "cat-1",
            date: Date(),
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )

        let restored = CloudKitRestoreMapper.mapEncounter(cloudEncounter)

        XCTAssertNil(restored.location.latitude)
        XCTAssertNil(restored.location.longitude)
    }

    // MARK: - mapAll

    func testMapAllConvertsMultipleCatsAndEncounters() {
        let cat1 = CloudCat(
            recordName: "cat-1", ownerID: "owner", name: "Whiskers",
            breed: "Persian", estimatedAge: "2", locationName: "Home",
            locationLatitude: nil, locationLongitude: nil,
            notes: "", isOwned: true, createdAt: Date(), photos: []
        )
        let cat2 = CloudCat(
            recordName: "cat-2", ownerID: "owner", name: "Mittens",
            breed: "Siamese", estimatedAge: "5", locationName: "Alley",
            locationLatitude: nil, locationLongitude: nil,
            notes: "", isOwned: false, createdAt: Date(), photos: []
        )
        let enc1 = CloudEncounter(
            recordName: "enc-1", ownerID: "owner", catRecordName: "cat-1",
            date: Date(), locationName: "Home",
            locationLatitude: nil, locationLongitude: nil,
            notes: "", photos: []
        )
        let enc2 = CloudEncounter(
            recordName: "enc-2", ownerID: "owner", catRecordName: "cat-2",
            date: Date(), locationName: "Alley",
            locationLatitude: nil, locationLongitude: nil,
            notes: "", photos: []
        )

        let (cats, encounters) = CloudKitRestoreMapper.mapAll(cats: [cat1, cat2], encounters: [enc1, enc2])

        XCTAssertEqual(cats.count, 2)
        XCTAssertEqual(encounters.count, 2)
        XCTAssertEqual(cats[0].cloudKitRecordName, "cat-1")
        XCTAssertEqual(cats[1].cloudKitRecordName, "cat-2")
        XCTAssertEqual(encounters[0].catRecordName, "cat-1")
        XCTAssertEqual(encounters[1].catRecordName, "cat-2")
    }

    func testMapAllHandlesEmptyInputs() {
        let (cats, encounters) = CloudKitRestoreMapper.mapAll(cats: [], encounters: [])

        XCTAssertTrue(cats.isEmpty)
        XCTAssertTrue(encounters.isEmpty)
    }
}
