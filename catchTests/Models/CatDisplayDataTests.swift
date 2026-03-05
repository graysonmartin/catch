import XCTest
import SwiftData
import CatchCore

@MainActor
final class CatDisplayDataTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try ModelContainer.forTesting()
        context = container.mainContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Local init

    func testLocalInitMapsBasicFields() {
        let cat = Fixtures.cat(name: "Whiskers", breed: "Domestic Shorthair", in: context)
        cat.estimatedAge = "3"
        cat.notes = "friendly"
        cat.isOwned = true

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.name, "Whiskers")
        XCTAssertEqual(data.breed, "Domestic Shorthair")
        XCTAssertEqual(data.estimatedAge, "3")
        XCTAssertEqual(data.notes, "friendly")
        XCTAssertTrue(data.isOwned)
    }

    func testLocalInitMapsEncounterCount() {
        let cat = Fixtures.cat(name: "Luna", in: context)
        _ = Fixtures.encounter(for: cat, in: context)
        _ = Fixtures.encounter(for: cat, in: context)

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.encounterCount, 2)
    }

    func testLocalInitMapsPhotos() {
        let photo1 = Data([0x01, 0x02])
        let photo2 = Data([0x03, 0x04])
        let cat = Fixtures.cat(name: "Photo Cat", in: context)
        cat.photos = [photo1, photo2]

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.firstPhotoData, photo1)
        XCTAssertEqual(data.allPhotos.count, 2)
    }

    func testLocalInitMapsLocationName() {
        let cat = Fixtures.cat(name: "Spot", in: context)
        cat.location = Location(name: "Back Alley")

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.locationName, "Back Alley")
    }

    func testLocalInitNilBreedBecomesEmptyString() {
        let cat = Fixtures.cat(name: "No Breed", breed: nil, in: context)

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.breed, "")
    }

    func testLocalInitStevenDetection() {
        let steven = Fixtures.cat(name: "Steven", breed: "Domestic Shorthair", in: context)
        let notSteven = Fixtures.cat(name: "Mittens", breed: "Domestic Shorthair", in: context)

        XCTAssertTrue(CatDisplayData(local: steven).isSteven)
        XCTAssertFalse(CatDisplayData(local: notSteven).isSteven)
    }

    func testLocalInitNoPhotosGivesNilFirstPhoto() {
        let cat = Fixtures.cat(name: "Shy", in: context)

        let data = CatDisplayData(local: cat)

        XCTAssertNil(data.firstPhotoData)
        XCTAssertTrue(data.allPhotos.isEmpty)
    }

    func testLocalInitNilNameUsesDisplayName() {
        let cat = Fixtures.cat(name: nil, in: context)

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.name, CatchStrings.Common.unnamedCatFallback)
        XCTAssertTrue(data.isUnnamed)
    }

    func testLocalInitEmptyNameUsesDisplayName() {
        let cat = Fixtures.cat(name: "", in: context)

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.name, CatchStrings.Common.unnamedCatFallback)
        XCTAssertTrue(data.isUnnamed)
    }

    func testLocalInitNamedCatIsNotUnnamed() {
        let cat = Fixtures.cat(name: "Whiskers", in: context)

        let data = CatDisplayData(local: cat)

        XCTAssertFalse(data.isUnnamed)
    }

    // MARK: - Remote init

    func testRemoteInitMapsBasicFields() {
        let cloudCat = makeCloudCat(
            name: "Chairman Meow",
            breed: "Persian",
            estimatedAge: "6",
            notes: "runs this block",
            isOwned: false
        )

        let data = CatDisplayData(remote: cloudCat, encounterCount: 3)

        XCTAssertEqual(data.id, "remote-1")
        XCTAssertEqual(data.name, "Chairman Meow")
        XCTAssertEqual(data.breed, "Persian")
        XCTAssertEqual(data.estimatedAge, "6")
        XCTAssertEqual(data.notes, "runs this block")
        XCTAssertFalse(data.isOwned)
        XCTAssertEqual(data.encounterCount, 3)
    }

    func testRemoteInitStevenIsAlwaysFalse() {
        let cloudCat = makeCloudCat(name: "Steven", breed: "Domestic Shorthair")

        let data = CatDisplayData(remote: cloudCat, encounterCount: 0)

        XCTAssertFalse(data.isSteven)
    }

    func testRemoteInitMapsPhotos() {
        let photo = Data([0xFF, 0xD8])
        let cloudCat = makeCloudCat(photos: [photo])

        let data = CatDisplayData(remote: cloudCat, encounterCount: 0)

        XCTAssertEqual(data.firstPhotoData, photo)
        XCTAssertEqual(data.allPhotos.count, 1)
    }

    func testRemoteInitMapsLocationName() {
        let cloudCat = makeCloudCat(locationName: "Coffee shop window")

        let data = CatDisplayData(remote: cloudCat, encounterCount: 0)

        XCTAssertEqual(data.locationName, "Coffee shop window")
    }

    // MARK: - Equatable / Hashable

    func testEqualityIncludesDisplayFields() {
        let base = makeCloudCat(recordName: "same-id", name: "A")

        let data1 = CatDisplayData(remote: base, encounterCount: 0)
        let data2 = CatDisplayData(remote: base, encounterCount: 0)
        XCTAssertEqual(data1, data2)

        let data3 = CatDisplayData(remote: base, encounterCount: 5)
        XCTAssertNotEqual(data1, data3, "Different encounter counts should not be equal")

        let different = makeCloudCat(recordName: "same-id", name: "B")
        let data4 = CatDisplayData(remote: different, encounterCount: 0)
        XCTAssertNotEqual(data1, data4, "Different names should not be equal")
    }

    func testInequalityForDifferentIDs() {
        let cat1 = makeCloudCat(recordName: "id-1")
        let cat2 = makeCloudCat(recordName: "id-2")

        let data1 = CatDisplayData(remote: cat1, encounterCount: 0)
        let data2 = CatDisplayData(remote: cat2, encounterCount: 0)

        XCTAssertNotEqual(data1, data2)
    }

    func testRemoteInitNilNameUsesDisplayName() {
        let cloudCat = makeCloudCat(name: nil)

        let data = CatDisplayData(remote: cloudCat, encounterCount: 0)

        XCTAssertEqual(data.name, CatchStrings.Common.unnamedCatFallback)
        XCTAssertTrue(data.isUnnamed)
    }

    // MARK: - Helpers

    private func makeCloudCat(
        recordName: String = "remote-1",
        name: String? = "Test Cat",
        breed: String = "",
        estimatedAge: String = "1",
        locationName: String = "Somewhere",
        notes: String = "",
        isOwned: Bool = false,
        photos: [Data] = []
    ) -> CloudCat {
        CloudCat(
            recordName: recordName,
            ownerID: "owner-1",
            name: name,
            breed: breed,
            estimatedAge: estimatedAge,
            locationName: locationName,
            locationLatitude: nil,
            locationLongitude: nil,
            notes: notes,
            isOwned: isOwned,
            createdAt: Date(),
            photos: photos
        )
    }
}
