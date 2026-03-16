import XCTest
@testable import MigrationLib

final class CloudKitExportModelsTests: XCTestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Profile

    func testProfileDecoding() throws {
        let json = """
        {
            "record_name": "rec_1",
            "apple_user_id": "apple_abc",
            "display_name": "Alice",
            "bio": "hi",
            "username": "alice",
            "is_private": false,
            "avatar_url": null
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(CKExportProfile.self, from: json)
        XCTAssertEqual(profile.recordName, "rec_1")
        XCTAssertEqual(profile.appleUserID, "apple_abc")
        XCTAssertEqual(profile.displayName, "Alice")
        XCTAssertEqual(profile.username, "alice")
        XCTAssertFalse(profile.isPrivate)
    }

    // MARK: - Cat

    func testCatDecoding() throws {
        let json = """
        {
            "record_name": "ck_cat_1",
            "owner_id": "apple_1",
            "name": "Whiskers",
            "breed": "Tabby",
            "estimated_age": "2 years",
            "location_name": "Park",
            "location_latitude": 40.7,
            "location_longitude": -73.9,
            "notes": "friendly",
            "is_owned": true,
            "created_at": "2024-01-15T10:00:00Z",
            "photo_urls": ["https://example.com/p1.jpg"]
        }
        """.data(using: .utf8)!

        let cat = try decoder.decode(CKExportCat.self, from: json)
        XCTAssertEqual(cat.recordName, "ck_cat_1")
        XCTAssertEqual(cat.name, "Whiskers")
        XCTAssertEqual(cat.locationLatitude, 40.7)
        XCTAssertEqual(cat.photoURLs.count, 1)
        XCTAssertTrue(cat.isOwned)
    }

    // MARK: - Encounter

    func testEncounterDecoding() throws {
        let json = """
        {
            "record_name": "ck_enc_1",
            "owner_id": "apple_1",
            "cat_record_name": "ck_cat_1",
            "date": "2024-06-01T08:30:00Z",
            "location_name": "Alley",
            "location_latitude": null,
            "location_longitude": null,
            "notes": "",
            "photo_urls": []
        }
        """.data(using: .utf8)!

        let encounter = try decoder.decode(CKExportEncounter.self, from: json)
        XCTAssertEqual(encounter.catRecordName, "ck_cat_1")
        XCTAssertNil(encounter.locationLatitude)
        XCTAssertTrue(encounter.photoURLs.isEmpty)
    }

    // MARK: - Follow

    func testFollowDecoding() throws {
        let json = """
        {
            "record_name": "ck_follow_1",
            "follower_id": "apple_1",
            "followee_id": "apple_2",
            "status": "active",
            "created_at": "2024-03-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let follow = try decoder.decode(CKExportFollow.self, from: json)
        XCTAssertEqual(follow.followerID, "apple_1")
        XCTAssertEqual(follow.followeeID, "apple_2")
        XCTAssertEqual(follow.status, "active")
    }

    // MARK: - Like

    func testLikeDecoding() throws {
        let json = """
        {
            "record_name": "ck_like_1",
            "encounter_record_name": "ck_enc_1",
            "user_id": "apple_1",
            "created_at": "2024-04-01T09:00:00Z"
        }
        """.data(using: .utf8)!

        let like = try decoder.decode(CKExportLike.self, from: json)
        XCTAssertEqual(like.encounterRecordName, "ck_enc_1")
        XCTAssertEqual(like.userID, "apple_1")
    }

    // MARK: - Comment

    func testCommentDecoding() throws {
        let json = """
        {
            "record_name": "ck_comment_1",
            "encounter_record_name": "ck_enc_1",
            "user_id": "apple_1",
            "text": "so cute!",
            "created_at": "2024-04-01T10:00:00Z"
        }
        """.data(using: .utf8)!

        let comment = try decoder.decode(CKExportComment.self, from: json)
        XCTAssertEqual(comment.text, "so cute!")
    }

    // MARK: - Full Export

    func testFullExportDecoding() throws {
        let json = """
        {
            "profiles": [],
            "cats": [],
            "encounters": [],
            "follows": [],
            "likes": [],
            "comments": []
        }
        """.data(using: .utf8)!

        let export = try JSONDecoder().decode(CloudKitExport.self, from: json)
        XCTAssertTrue(export.profiles.isEmpty)
        XCTAssertTrue(export.cats.isEmpty)
        XCTAssertTrue(export.encounters.isEmpty)
        XCTAssertTrue(export.follows.isEmpty)
        XCTAssertTrue(export.likes.isEmpty)
        XCTAssertTrue(export.comments.isEmpty)
    }
}
