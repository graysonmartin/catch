import XCTest
@testable import CatchCore

@MainActor
final class SupabaseFeedMapperTests: XCTestCase {

    // MARK: - Encounter Mapping

    func testToCloudEncounterMapsAllFields() {
        let row = SupabaseFeedRow.fixture()
        let encounter = SupabaseFeedMapper.toCloudEncounter(row)

        XCTAssertEqual(encounter.recordName, row.id.uuidString)
        XCTAssertEqual(encounter.ownerID, row.ownerID.uuidString)
        XCTAssertEqual(encounter.catRecordName, row.catID.uuidString)
        XCTAssertEqual(encounter.date, row.date)
        XCTAssertEqual(encounter.locationName, "test park")
        XCTAssertEqual(encounter.locationLatitude, 37.7749)
        XCTAssertEqual(encounter.locationLongitude, -122.4194)
        XCTAssertEqual(encounter.notes, "spotted near bench")
        XCTAssertEqual(encounter.photoUrls, ["https://example.com/photo.jpg"])
        XCTAssertTrue(encounter.photos.isEmpty)
    }

    func testToCloudEncounterHandlesNilOptionals() {
        let row = SupabaseFeedRow.fixture(
            locationName: nil,
            locationLat: nil,
            locationLng: nil,
            notes: nil,
            photoUrls: []
        )
        let encounter = SupabaseFeedMapper.toCloudEncounter(row)

        XCTAssertEqual(encounter.locationName, "")
        XCTAssertNil(encounter.locationLatitude)
        XCTAssertNil(encounter.locationLongitude)
        XCTAssertEqual(encounter.notes, "")
        XCTAssertTrue(encounter.photoUrls.isEmpty)
    }

    // MARK: - Cat Mapping

    func testToCloudCatMapsAllFields() {
        let cat = SupabaseFeedCat.fixture()
        let ownerID = "owner-123"
        let cloudCat = SupabaseFeedMapper.toCloudCat(cat, ownerID: ownerID)

        XCTAssertEqual(cloudCat.recordName, cat.id.uuidString)
        XCTAssertEqual(cloudCat.ownerID, ownerID)
        XCTAssertEqual(cloudCat.name, "Whiskers")
        XCTAssertEqual(cloudCat.breed, "tabby")
        XCTAssertEqual(cloudCat.isOwned, false)
        XCTAssertTrue(cloudCat.photos.isEmpty)
    }

    func testToCloudCatEmptyNameMapsToNil() {
        let cat = SupabaseFeedCat.fixture(name: "")
        let cloudCat = SupabaseFeedMapper.toCloudCat(cat, ownerID: "owner")

        XCTAssertNil(cloudCat.name)
    }

    // MARK: - Profile Mapping

    func testToCloudUserProfileMapsAllFields() {
        let profile = SupabaseFeedProfile.fixture()
        let cloudProfile = SupabaseFeedMapper.toCloudUserProfile(profile)

        XCTAssertEqual(cloudProfile.recordName, profile.id.uuidString)
        XCTAssertEqual(cloudProfile.appleUserID, profile.id.uuidString)
        XCTAssertEqual(cloudProfile.displayName, "alice")
        XCTAssertEqual(cloudProfile.username, "alice99")
        XCTAssertEqual(cloudProfile.bio, "cat lover")
        XCTAssertFalse(cloudProfile.isPrivate)
        XCTAssertNil(cloudProfile.avatarData)
        XCTAssertEqual(cloudProfile.avatarURL, "https://example.com/avatar.jpg")
    }
}

// MARK: - Fixtures

extension SupabaseFeedRow {
    static func fixture(
        id: UUID = UUID(),
        ownerID: UUID = UUID(),
        catID: UUID = UUID(),
        date: Date = Date(),
        locationName: String? = "test park",
        locationLat: Double? = 37.7749,
        locationLng: Double? = -122.4194,
        notes: String? = "spotted near bench",
        photoUrls: [String] = ["https://example.com/photo.jpg"],
        likeCount: Int = 3,
        commentCount: Int = 1,
        createdAt: Date = Date(),
        cat: SupabaseFeedCat = .fixture(),
        owner: SupabaseFeedProfile = .fixture()
    ) -> SupabaseFeedRow {
        SupabaseFeedRow(
            id: id,
            ownerID: ownerID,
            catID: catID,
            date: date,
            locationName: locationName,
            locationLat: locationLat,
            locationLng: locationLng,
            notes: notes,
            photoUrls: photoUrls,
            likeCount: likeCount,
            commentCount: commentCount,
            createdAt: createdAt,
            cat: cat,
            owner: owner
        )
    }
}

extension SupabaseFeedCat {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Whiskers",
        breed: String? = "tabby",
        estimatedAge: String? = "2 years",
        locationName: String? = "park",
        locationLat: Double? = nil,
        locationLng: Double? = nil,
        notes: String? = nil,
        isOwned: Bool = false,
        photoUrls: [String] = [],
        createdAt: Date = Date()
    ) -> SupabaseFeedCat {
        SupabaseFeedCat(
            id: id,
            name: name,
            breed: breed,
            estimatedAge: estimatedAge,
            locationName: locationName,
            locationLat: locationLat,
            locationLng: locationLng,
            notes: notes,
            isOwned: isOwned,
            photoUrls: photoUrls,
            createdAt: createdAt
        )
    }
}

extension SupabaseFeedProfile {
    static func fixture(
        id: UUID = UUID(),
        displayName: String = "alice",
        username: String = "alice99",
        bio: String = "cat lover",
        isPrivate: Bool = false,
        avatarUrl: String? = "https://example.com/avatar.jpg"
    ) -> SupabaseFeedProfile {
        SupabaseFeedProfile(
            id: id,
            displayName: displayName,
            username: username,
            bio: bio,
            isPrivate: isPrivate,
            avatarUrl: avatarUrl
        )
    }
}
