import XCTest
@testable import CatchCore

final class SupabaseSocialModelsTests: XCTestCase {

    // MARK: - SupabaseLike

    func testSupabaseLikeToDomain() {
        let id = UUID()
        let encounterID = UUID()
        let userID = UUID()
        let date = Date()
        let like = SupabaseLike(id: id, encounterID: encounterID, userID: userID, createdAt: date)

        let domain = like.toDomain()

        XCTAssertEqual(domain.id, id.uuidString.lowercased())
        XCTAssertEqual(domain.encounterRecordName, encounterID.uuidString.lowercased())
        XCTAssertEqual(domain.userID, userID.uuidString.lowercased())
        XCTAssertEqual(domain.createdAt, date)
    }

    func testSupabaseLikeDecodesFromJSON() throws {
        let id = UUID()
        let encounterID = UUID()
        let userID = UUID()
        let json = """
        {
            "id": "\(id.uuidString.lowercased())",
            "encounter_id": "\(encounterID.uuidString.lowercased())",
            "user_id": "\(userID.uuidString.lowercased())",
            "created_at": "2025-03-15T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let like = try decoder.decode(SupabaseLike.self, from: Data(json.utf8))

        XCTAssertEqual(like.id, id)
        XCTAssertEqual(like.encounterID, encounterID)
        XCTAssertEqual(like.userID, userID)
    }

    // MARK: - SupabaseLikeWithProfile

    func testSupabaseLikeWithProfileToLikedByUser() {
        let id = UUID()
        let userID = UUID()
        let date = Date()
        let like = SupabaseLikeWithProfile(
            id: id,
            encounterID: UUID(),
            userID: userID,
            createdAt: date,
            profiles: .init(displayName: "CatPerson", username: "catperson99")
        )

        let user = like.toLikedByUser()

        XCTAssertEqual(user.id, id.uuidString.lowercased())
        XCTAssertEqual(user.userID, userID.uuidString.lowercased())
        XCTAssertEqual(user.displayName, "CatPerson")
        XCTAssertEqual(user.username, "catperson99")
        XCTAssertEqual(user.likedAt, date)
    }

    func testSupabaseLikeWithProfileFallsBackToTruncatedID() {
        let userID = UUID()
        let like = SupabaseLikeWithProfile(
            id: UUID(),
            encounterID: UUID(),
            userID: userID,
            createdAt: Date(),
            profiles: nil
        )

        let user = like.toLikedByUser()

        XCTAssertEqual(user.displayName, String(userID.uuidString.lowercased().prefix(8)))
        XCTAssertNil(user.username)
    }

    // MARK: - SupabaseComment

    func testSupabaseCommentToDomain() {
        let id = UUID()
        let encounterID = UUID()
        let userID = UUID()
        let date = Date()
        let comment = SupabaseComment(
            id: id,
            encounterID: encounterID,
            userID: userID,
            text: "nice cat",
            createdAt: date
        )

        let domain = comment.toDomain()

        XCTAssertEqual(domain.id, id.uuidString.lowercased())
        XCTAssertEqual(domain.encounterRecordName, encounterID.uuidString.lowercased())
        XCTAssertEqual(domain.userID, userID.uuidString.lowercased())
        XCTAssertEqual(domain.text, "nice cat")
        XCTAssertEqual(domain.createdAt, date)
        XCTAssertNil(domain.displayName)
    }

    // MARK: - SupabaseCommentWithProfile

    func testSupabaseCommentWithProfileToDomain() {
        let id = UUID()
        let encounterID = UUID()
        let userID = UUID()
        let comment = SupabaseCommentWithProfile(
            id: id,
            encounterID: encounterID,
            userID: userID,
            text: "obsessed",
            createdAt: Date(),
            profiles: .init(displayName: "CatFan")
        )

        let domain = comment.toDomain()

        XCTAssertEqual(domain.text, "obsessed")
        XCTAssertEqual(domain.displayName, "CatFan")
    }

    func testSupabaseCommentWithProfileNilProfileReturnsNilDisplayName() {
        let comment = SupabaseCommentWithProfile(
            id: UUID(),
            encounterID: UUID(),
            userID: UUID(),
            text: "hey",
            createdAt: Date(),
            profiles: nil
        )

        let domain = comment.toDomain()

        XCTAssertNil(domain.displayName)
    }

    func testSupabaseCommentDecodesFromJSON() throws {
        let id = UUID()
        let encounterID = UUID()
        let userID = UUID()
        let json = """
        {
            "id": "\(id.uuidString.lowercased())",
            "encounter_id": "\(encounterID.uuidString.lowercased())",
            "user_id": "\(userID.uuidString.lowercased())",
            "text": "what a legend",
            "created_at": "2025-03-15T10:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let comment = try decoder.decode(SupabaseComment.self, from: Data(json.utf8))

        XCTAssertEqual(comment.id, id)
        XCTAssertEqual(comment.text, "what a legend")
    }

    // MARK: - SupabaseEncounterCounts

    func testEncounterCountsDecodes() throws {
        let id = UUID()
        let json = """
        {
            "id": "\(id.uuidString.lowercased())",
            "like_count": 42,
            "comment_count": 7
        }
        """
        let counts = try JSONDecoder().decode(
            SupabaseEncounterCounts.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(counts.id, id)
        XCTAssertEqual(counts.likeCount, 42)
        XCTAssertEqual(counts.commentCount, 7)
    }

    // MARK: - Insert Payloads

    func testLikeInsertPayloadEncodesCorrectKeys() throws {
        let payload = SupabaseLikeInsertPayload(encounterID: "enc-1", userID: "user-1")
        let data = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(dict?["encounter_id"] as? String, "enc-1")
        XCTAssertEqual(dict?["user_id"] as? String, "user-1")
        XCTAssertNil(dict?["encounterID"])
    }

    func testCommentInsertPayloadEncodesCorrectKeys() throws {
        let payload = SupabaseCommentInsertPayload(
            encounterID: "enc-1",
            userID: "user-1",
            text: "nice"
        )
        let data = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(dict?["encounter_id"] as? String, "enc-1")
        XCTAssertEqual(dict?["user_id"] as? String, "user-1")
        XCTAssertEqual(dict?["text"] as? String, "nice")
    }
}
