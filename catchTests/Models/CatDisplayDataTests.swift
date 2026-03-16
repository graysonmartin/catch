import XCTest
import CatchCore

@MainActor
final class CatDisplayDataTests: XCTestCase {

    // MARK: - Local init

    func testLocalInitMapsBasicFields() {
        var cat = Fixtures.cat(name: "Whiskers", breed: "Domestic Shorthair")
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
        let cat = Fixtures.cat(name: "Luna")
        var catWithEnc = cat
        catWithEnc.encounters = [
            Fixtures.encounter(for: cat),
            Fixtures.encounter(for: cat)
        ]

        let data = CatDisplayData(local: catWithEnc)

        XCTAssertEqual(data.encounterCount, 2)
    }

    func testLocalInitMapsPhotoUrl() {
        var cat = Fixtures.cat(name: "Photo Cat")
        cat.photoUrls = ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"]

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.firstPhotoUrl, "https://example.com/photo1.jpg")
    }

    func testLocalInitMapsLocationName() {
        var cat = Fixtures.cat(name: "Spot")
        cat.location = Location(name: "Back Alley")

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.locationName, "Back Alley")
    }

    func testLocalInitNilBreedBecomesEmptyString() {
        let cat = Fixtures.cat(name: "No Breed", breed: nil)

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.breed, "")
    }

    func testLocalInitStevenDetection() {
        let steven = Fixtures.cat(name: "Steven", breed: "Domestic Shorthair")
        let notSteven = Fixtures.cat(name: "Mittens", breed: "Domestic Shorthair")

        XCTAssertTrue(CatDisplayData(local: steven).isSteven)
        XCTAssertFalse(CatDisplayData(local: notSteven).isSteven)
    }

    func testLocalInitNoPhotosGivesNilFirstPhoto() {
        let cat = Fixtures.cat(name: "Shy")

        let data = CatDisplayData(local: cat)

        XCTAssertNil(data.firstPhotoUrl)
    }

    func testLocalInitNilNameUsesDisplayName() {
        let cat = Fixtures.cat(name: nil)

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.name, CatchStrings.Common.unnamedCatFallback)
        XCTAssertTrue(data.isUnnamed)
    }

    func testLocalInitEmptyNameUsesDisplayName() {
        let cat = Fixtures.cat(name: "")

        let data = CatDisplayData(local: cat)

        XCTAssertEqual(data.name, CatchStrings.Common.unnamedCatFallback)
        XCTAssertTrue(data.isUnnamed)
    }

    func testLocalInitNamedCatIsNotUnnamed() {
        let cat = Fixtures.cat(name: "Whiskers")

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
