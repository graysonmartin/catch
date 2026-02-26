import XCTest
import CloudKit

@MainActor
final class CommentRecordMapperTests: XCTestCase {

    func test_recordFromComment_setsCorrectFields() {
        let comment = EncounterComment(
            id: "user1_comment_abc",
            encounterRecordName: "enc1",
            userID: "user1",
            text: "nice cat",
            createdAt: Date()
        )

        let record = CommentRecordMapper.record(from: comment)

        XCTAssertEqual(record.recordID.recordName, "user1_comment_abc")
        XCTAssertEqual(record.recordType, "EncounterComment")
        XCTAssertEqual(record["encounterRecordName"] as? String, "enc1")
        XCTAssertEqual(record["userID"] as? String, "user1")
        XCTAssertEqual(record["text"] as? String, "nice cat")
    }

    func test_commentFromRecord_parsesCorrectly() {
        let recordID = CKRecord.ID(recordName: "user1_comment_abc")
        let record = CKRecord(recordType: "EncounterComment", recordID: recordID)
        record["encounterRecordName"] = "enc1"
        record["userID"] = "user1"
        record["text"] = "cool cat"

        let comment = CommentRecordMapper.comment(from: record)

        XCTAssertNotNil(comment)
        XCTAssertEqual(comment?.id, "user1_comment_abc")
        XCTAssertEqual(comment?.encounterRecordName, "enc1")
        XCTAssertEqual(comment?.userID, "user1")
        XCTAssertEqual(comment?.text, "cool cat")
    }

    func test_commentFromRecord_returnsNilForMissingText() {
        let record = CKRecord(recordType: "EncounterComment")
        record["encounterRecordName"] = "enc1"
        record["userID"] = "user1"

        let comment = CommentRecordMapper.comment(from: record)

        XCTAssertNil(comment)
    }

    func test_commentFromRecord_returnsNilForMissingUserID() {
        let record = CKRecord(recordType: "EncounterComment")
        record["encounterRecordName"] = "enc1"
        record["text"] = "test"

        let comment = CommentRecordMapper.comment(from: record)

        XCTAssertNil(comment)
    }

    func test_commentFromRecord_returnsNilForMissingEncounterRecordName() {
        let record = CKRecord(recordType: "EncounterComment")
        record["userID"] = "user1"
        record["text"] = "test"

        let comment = CommentRecordMapper.comment(from: record)

        XCTAssertNil(comment)
    }

    func test_roundTrip_preservesData() {
        let original = EncounterComment(
            id: "abc_comment_xyz",
            encounterRecordName: "xyz",
            userID: "abc",
            text: "great encounter",
            createdAt: Date()
        )

        let record = CommentRecordMapper.record(from: original)
        let restored = CommentRecordMapper.comment(from: record)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.encounterRecordName, original.encounterRecordName)
        XCTAssertEqual(restored?.userID, original.userID)
        XCTAssertEqual(restored?.text, original.text)
    }
}
