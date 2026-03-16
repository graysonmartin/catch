import XCTest
@testable import CatchCore

final class FeedEncounterDetailMapperTests: XCTestCase {

    // MARK: - Single Mapping

    func testMapWithCatPopulatesAllFields() {
        let encounter = makeEncounter(
            recordName: "enc-1",
            catRecordName: "cat-1",
            locationName: "Central Park",
            notes: "friendly cat"
        )
        let cat = makeCat(
            recordName: "cat-1",
            name: "Whiskers",
            breed: "Domestic Shorthair",
            isOwned: true
        )

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: true
        )

        XCTAssertEqual(detail.recordName, "enc-1")
        XCTAssertEqual(detail.catName, "Whiskers")
        XCTAssertEqual(detail.breed, "Domestic Shorthair")
        XCTAssertFalse(detail.isUnnamed)
        XCTAssertTrue(detail.isOwned)
        XCTAssertEqual(detail.locationName, "Central Park")
        XCTAssertEqual(detail.notes, "friendly cat")
        XCTAssertTrue(detail.isFirstEncounter)
    }

    func testMapWithNilCatUsesDefaults() {
        let encounter = makeEncounter(recordName: "enc-2", catRecordName: "missing-cat")

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: nil,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.recordName, "enc-2")
        XCTAssertEqual(detail.breed, "")
        XCTAssertTrue(detail.isUnnamed)
        XCTAssertFalse(detail.isOwned)
        XCTAssertFalse(detail.isFirstEncounter)
        XCTAssertTrue(detail.catPhotos.isEmpty)
    }

    func testMapWithUnnamedCatSetsIsUnnamed() {
        let encounter = makeEncounter(recordName: "enc-3", catRecordName: "cat-3")
        let cat = makeCat(recordName: "cat-3", name: nil, breed: "")

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertTrue(detail.isUnnamed)
    }

    func testMapWithEmptyNameCatSetsIsUnnamed() {
        let encounter = makeEncounter(recordName: "enc-4", catRecordName: "cat-4")
        let cat = makeCat(recordName: "cat-4", name: "", breed: "Persian")

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertTrue(detail.isUnnamed)
        XCTAssertEqual(detail.breed, "Persian")
    }

    // MARK: - Display Photos

    func testDisplayPhotosUsesEncounterPhotosWhenAvailable() {
        let encounterPhotos = [Data([1, 2, 3])]
        let catPhotos = [Data([4, 5, 6])]
        let encounter = makeEncounter(recordName: "enc-5", catRecordName: "cat-5", photos: encounterPhotos)
        let cat = makeCat(recordName: "cat-5", name: "Test", breed: "", photos: catPhotos)

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.displayPhotos, encounterPhotos)
    }

    func testDisplayPhotosFallsToCatPhotosWhenEncounterHasNone() {
        let catPhotos = [Data([4, 5, 6])]
        let encounter = makeEncounter(recordName: "enc-6", catRecordName: "cat-6", photos: [])
        let cat = makeCat(recordName: "cat-6", name: "Test", breed: "", photos: catPhotos)

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.displayPhotos, catPhotos)
    }

    func testThumbnailPhotoReturnsFirstCatPhoto() {
        let catPhotos = [Data([7, 8, 9]), Data([10, 11, 12])]
        let encounter = makeEncounter(recordName: "enc-7", catRecordName: "cat-7")
        let cat = makeCat(recordName: "cat-7", name: "Test", breed: "", photos: catPhotos)

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.thumbnailPhoto, Data([7, 8, 9]))
    }

    func testThumbnailPhotoIsNilWhenNoCatPhotos() {
        let encounter = makeEncounter(recordName: "enc-8", catRecordName: "cat-8")

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: nil,
            isFirstEncounter: false
        )

        XCTAssertNil(detail.thumbnailPhoto)
    }

    // MARK: - Photo URLs

    func testDisplayPhotoUrlsUsesEncounterUrlsWhenAvailable() {
        let encounter = makeEncounter(recordName: "enc-9", catRecordName: "cat-9", photoUrls: ["enc-url"])
        let cat = makeCat(recordName: "cat-9", name: "Test", breed: "", photoUrls: ["cat-url"])

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.displayPhotoUrls, ["enc-url"])
    }

    func testDisplayPhotoUrlsFallsToCatUrlsWhenEncounterHasNone() {
        let encounter = makeEncounter(recordName: "enc-10", catRecordName: "cat-10")
        let cat = makeCat(recordName: "cat-10", name: "Test", breed: "", photoUrls: ["cat-url"])

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.displayPhotoUrls, ["cat-url"])
    }

    func testThumbnailPhotoUrlReturnsFirstCatPhotoUrl() {
        let encounter = makeEncounter(recordName: "enc-11", catRecordName: "cat-11")
        let cat = makeCat(recordName: "cat-11", name: "Test", breed: "", photoUrls: ["url-a", "url-b"])

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: cat,
            isFirstEncounter: false
        )

        XCTAssertEqual(detail.thumbnailPhotoUrl, "url-a")
    }

    func testThumbnailPhotoUrlIsNilWhenNoCat() {
        let encounter = makeEncounter(recordName: "enc-12", catRecordName: "cat-12")

        let detail = FeedEncounterDetailMapper.map(
            encounter: encounter,
            cat: nil,
            isFirstEncounter: false
        )

        XCTAssertNil(detail.thumbnailPhotoUrl)
    }

    // MARK: - Batch Mapping

    func testMapBatchMatchesCatsToEncounters() {
        let cat1 = makeCat(recordName: "cat-a", name: "Alpha", breed: "Siamese")
        let cat2 = makeCat(recordName: "cat-b", name: "Beta", breed: "Persian")
        let enc1 = makeEncounter(recordName: "enc-a", catRecordName: "cat-a", daysAgo: 0)
        let enc2 = makeEncounter(recordName: "enc-b", catRecordName: "cat-b", daysAgo: 1)

        let details = FeedEncounterDetailMapper.mapBatch(
            encounters: [enc1, enc2],
            cats: [cat1, cat2],
            allEncounters: [enc1, enc2]
        )

        XCTAssertEqual(details.count, 2)
        XCTAssertEqual(details[0].catName, "Alpha")
        XCTAssertEqual(details[0].breed, "Siamese")
        XCTAssertEqual(details[1].catName, "Beta")
        XCTAssertEqual(details[1].breed, "Persian")
    }

    func testMapBatchDetectsFirstEncounter() {
        let cat = makeCat(recordName: "cat-x", name: "Xena", breed: "")
        let earlier = makeEncounter(recordName: "enc-early", catRecordName: "cat-x", daysAgo: 5)
        let later = makeEncounter(recordName: "enc-late", catRecordName: "cat-x", daysAgo: 0)

        let details = FeedEncounterDetailMapper.mapBatch(
            encounters: [later, earlier],
            cats: [cat],
            allEncounters: [later, earlier]
        )

        let earlyDetail = details.first { $0.recordName == "enc-early" }
        let lateDetail = details.first { $0.recordName == "enc-late" }

        XCTAssertEqual(earlyDetail?.isFirstEncounter, true)
        XCTAssertEqual(lateDetail?.isFirstEncounter, false)
    }

    func testMapBatchHandlesMissingCat() {
        let enc = makeEncounter(recordName: "enc-orphan", catRecordName: "cat-ghost")

        let details = FeedEncounterDetailMapper.mapBatch(
            encounters: [enc],
            cats: [],
            allEncounters: [enc]
        )

        XCTAssertEqual(details.count, 1)
        XCTAssertEqual(details[0].breed, "")
        XCTAssertTrue(details[0].isUnnamed)
    }

    func testMapBatchReturnsCorrectCountForDuplicateCats() {
        let cat = makeCat(recordName: "cat-dup", name: "Dup", breed: "Domestic Shorthair")
        // Simulate duplicate cat records (same recordName) — should use the first
        let cats = [cat, makeCat(recordName: "cat-dup", name: "Other", breed: "Siamese")]
        let enc = makeEncounter(recordName: "enc-dup", catRecordName: "cat-dup")

        let details = FeedEncounterDetailMapper.mapBatch(
            encounters: [enc],
            cats: cats,
            allEncounters: [enc]
        )

        XCTAssertEqual(details.count, 1)
        XCTAssertEqual(details[0].catName, "Dup")
        XCTAssertEqual(details[0].breed, "Domestic Shorthair")
    }

    // MARK: - Helpers

    private func makeEncounter(
        recordName: String,
        catRecordName: String,
        locationName: String = "",
        notes: String = "",
        photos: [Data] = [],
        photoUrls: [String] = [],
        daysAgo: Int = 0
    ) -> CloudEncounter {
        CloudEncounter(
            recordName: recordName,
            ownerID: "test-user",
            catRecordName: catRecordName,
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            locationName: locationName,
            locationLatitude: nil,
            locationLongitude: nil,
            notes: notes,
            photos: photos,
            photoUrls: photoUrls
        )
    }

    private func makeCat(
        recordName: String,
        name: String?,
        breed: String,
        isOwned: Bool = false,
        photos: [Data] = [],
        photoUrls: [String] = []
    ) -> CloudCat {
        CloudCat(
            recordName: recordName,
            ownerID: "test-user",
            name: name,
            breed: breed,
            estimatedAge: "",
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: isOwned,
            createdAt: Date(),
            photos: photos,
            photoUrls: photoUrls
        )
    }
}
