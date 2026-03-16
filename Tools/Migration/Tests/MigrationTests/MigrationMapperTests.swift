import XCTest
@testable import MigrationLib

final class MigrationMapperTests: XCTestCase {

    private let fixedDate = Date(timeIntervalSince1970: 1700000000)

    // MARK: - Profile Mapping

    func testMapProfileWithUsername() {
        let profile = CKExportProfile(
            recordName: "rec_1",
            appleUserID: "apple_1",
            displayName: "Alice",
            bio: "cat lover",
            username: "alice_cats",
            isPrivate: false,
            avatarURL: nil
        )

        let result = MigrationMapper.mapProfile(profile, supabaseUserID: "supa_1")

        XCTAssertEqual(result.id, "supa_1")
        XCTAssertEqual(result.displayName, "Alice")
        XCTAssertEqual(result.username, "alice_cats")
        XCTAssertEqual(result.bio, "cat lover")
        XCTAssertFalse(result.isPrivate)
        XCTAssertTrue(result.showCats)
        XCTAssertTrue(result.showEncounters)
        XCTAssertNil(result.avatarUrl)
    }

    func testMapProfileWithoutUsernameGeneratesFallback() {
        let profile = CKExportProfile(
            recordName: "rec_1",
            appleUserID: "apple_user_12345",
            displayName: "Bob",
            bio: "",
            username: nil,
            isPrivate: true,
            avatarURL: nil
        )

        let result = MigrationMapper.mapProfile(profile, supabaseUserID: "supa_1")

        XCTAssertEqual(result.username, "apple_user_1_migrated")
        XCTAssertTrue(result.isPrivate)
    }

    func testMapProfileWithEmptyUsernameGeneratesFallback() {
        let profile = CKExportProfile(
            recordName: "rec_1",
            appleUserID: "ABCDEFGHIJKLMN",
            displayName: "Charlie",
            bio: "",
            username: "",
            isPrivate: false,
            avatarURL: nil
        )

        let result = MigrationMapper.mapProfile(profile, supabaseUserID: "supa_1")

        XCTAssertEqual(result.username, "abcdefghijkl_migrated")
    }

    // MARK: - Cat Mapping

    func testMapCatWithAllFields() {
        let cat = CKExportCat(
            recordName: "ck_cat_1",
            ownerID: "apple_1",
            name: "Whiskers",
            breed: "Tabby",
            estimatedAge: "3 years",
            locationName: "Park Avenue",
            locationLatitude: 40.7,
            locationLongitude: -73.9,
            notes: "Very friendly",
            isOwned: true,
            createdAt: fixedDate,
            photoURLs: ["https://example.com/photo1.jpg"]
        )

        let result = MigrationMapper.mapCat(
            cat,
            supabaseOwnerID: "supa_owner",
            supabaseCatID: "supa_cat",
            photoUrls: ["https://supabase.co/photo1.jpg"]
        )

        XCTAssertEqual(result.id, "supa_cat")
        XCTAssertEqual(result.ownerID, "supa_owner")
        XCTAssertEqual(result.name, "Whiskers")
        XCTAssertEqual(result.breed, "Tabby")
        XCTAssertEqual(result.estimatedAge, "3 years")
        XCTAssertEqual(result.locationName, "Park Avenue")
        XCTAssertEqual(result.locationLat, 40.7)
        XCTAssertEqual(result.locationLng, -73.9)
        XCTAssertEqual(result.notes, "Very friendly")
        XCTAssertTrue(result.isOwned)
        XCTAssertEqual(result.photoUrls, ["https://supabase.co/photo1.jpg"])
        XCTAssertEqual(result.createdAt, fixedDate)
    }

    func testMapCatWithEmptyFieldsBecomesNil() {
        let cat = CKExportCat(
            recordName: "ck_cat_2",
            ownerID: "apple_1",
            name: nil,
            breed: "",
            estimatedAge: "",
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: fixedDate,
            photoURLs: []
        )

        let result = MigrationMapper.mapCat(
            cat,
            supabaseOwnerID: "supa_owner",
            supabaseCatID: "supa_cat",
            photoUrls: []
        )

        XCTAssertEqual(result.name, "")
        XCTAssertNil(result.breed)
        XCTAssertNil(result.estimatedAge)
        XCTAssertNil(result.locationName)
        XCTAssertNil(result.locationLat)
        XCTAssertNil(result.locationLng)
        XCTAssertNil(result.notes)
        XCTAssertFalse(result.isOwned)
        XCTAssertTrue(result.photoUrls.isEmpty)
    }

    // MARK: - Encounter Mapping

    func testMapEncounterWithAllFields() {
        let encounter = CKExportEncounter(
            recordName: "ck_enc_1",
            ownerID: "apple_1",
            catRecordName: "ck_cat_1",
            date: fixedDate,
            locationName: "Alley",
            locationLatitude: 40.7,
            locationLongitude: -73.9,
            notes: "Spotted sleeping",
            photoURLs: []
        )

        let result = MigrationMapper.mapEncounter(
            encounter,
            supabaseOwnerID: "supa_owner",
            supabaseEncounterID: "supa_enc",
            supabaseCatID: "supa_cat",
            photoUrls: []
        )

        XCTAssertEqual(result.id, "supa_enc")
        XCTAssertEqual(result.ownerID, "supa_owner")
        XCTAssertEqual(result.catID, "supa_cat")
        XCTAssertEqual(result.date, fixedDate)
        XCTAssertEqual(result.locationName, "Alley")
        XCTAssertEqual(result.notes, "Spotted sleeping")
    }

    func testMapEncounterEmptyStringsBecomesNil() {
        let encounter = CKExportEncounter(
            recordName: "ck_enc_2",
            ownerID: "apple_1",
            catRecordName: "ck_cat_1",
            date: fixedDate,
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photoURLs: []
        )

        let result = MigrationMapper.mapEncounter(
            encounter,
            supabaseOwnerID: "supa_owner",
            supabaseEncounterID: "supa_enc",
            supabaseCatID: "supa_cat",
            photoUrls: []
        )

        XCTAssertNil(result.locationName)
        XCTAssertNil(result.notes)
    }

    // MARK: - Follow Mapping

    func testMapFollow() {
        let follow = CKExportFollow(
            recordName: "ck_follow_1",
            followerID: "apple_1",
            followeeID: "apple_2",
            status: "active",
            createdAt: fixedDate
        )

        let result = MigrationMapper.mapFollow(
            follow,
            supabaseFollowerID: "supa_1",
            supabaseFolloweeID: "supa_2"
        )

        XCTAssertEqual(result.followerID, "supa_1")
        XCTAssertEqual(result.followeeID, "supa_2")
        XCTAssertEqual(result.status, "active")
    }

    func testMapFollowPreservesStatus() {
        let follow = CKExportFollow(
            recordName: "ck_follow_2",
            followerID: "apple_1",
            followeeID: "apple_2",
            status: "pending",
            createdAt: fixedDate
        )

        let result = MigrationMapper.mapFollow(
            follow,
            supabaseFollowerID: "supa_1",
            supabaseFolloweeID: "supa_2"
        )

        XCTAssertEqual(result.status, "pending")
    }

    // MARK: - Like Mapping

    func testMapLike() {
        let like = CKExportLike(
            recordName: "ck_like_1",
            encounterRecordName: "ck_enc_1",
            userID: "apple_1",
            createdAt: fixedDate
        )

        let result = MigrationMapper.mapLike(
            like,
            supabaseUserID: "supa_1",
            supabaseEncounterID: "supa_enc_1"
        )

        XCTAssertEqual(result.encounterID, "supa_enc_1")
        XCTAssertEqual(result.userID, "supa_1")
    }

    // MARK: - Comment Mapping

    func testMapComment() {
        let comment = CKExportComment(
            recordName: "ck_comment_1",
            encounterRecordName: "ck_enc_1",
            userID: "apple_1",
            text: "cute cat!",
            createdAt: fixedDate
        )

        let result = MigrationMapper.mapComment(
            comment,
            supabaseUserID: "supa_1",
            supabaseEncounterID: "supa_enc_1"
        )

        XCTAssertEqual(result.encounterID, "supa_enc_1")
        XCTAssertEqual(result.userID, "supa_1")
        XCTAssertEqual(result.text, "cute cat!")
    }
}
