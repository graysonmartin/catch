import XCTest
@testable import CatchCore
import CloudKit

@MainActor
final class LikeRecordMapperTests: XCTestCase {

    func test_recordFromLike_setsCorrectFields() {
        let like = EncounterLike(
            id: "user1_like_enc1",
            encounterRecordName: "enc1",
            userID: "user1",
            createdAt: Date()
        )

        let record = LikeRecordMapper.record(from: like)

        XCTAssertEqual(record.recordID.recordName, "user1_like_enc1")
        XCTAssertEqual(record.recordType, "EncounterLike")
        XCTAssertEqual(record["encounterRecordName"] as? String, "enc1")
        XCTAssertEqual(record["userID"] as? String, "user1")
    }

    func test_likeFromRecord_parsesCorrectly() {
        let recordID = CKRecord.ID(recordName: "user1_like_enc1")
        let record = CKRecord(recordType: "EncounterLike", recordID: recordID)
        record["encounterRecordName"] = "enc1"
        record["userID"] = "user1"

        let like = LikeRecordMapper.like(from: record)

        XCTAssertNotNil(like)
        XCTAssertEqual(like?.id, "user1_like_enc1")
        XCTAssertEqual(like?.encounterRecordName, "enc1")
        XCTAssertEqual(like?.userID, "user1")
    }

    func test_likeFromRecord_returnsNilForMissingEncounterRecordName() {
        let record = CKRecord(recordType: "EncounterLike")
        record["userID"] = "user1"

        let like = LikeRecordMapper.like(from: record)

        XCTAssertNil(like)
    }

    func test_likeFromRecord_returnsNilForMissingUserID() {
        let record = CKRecord(recordType: "EncounterLike")
        record["encounterRecordName"] = "enc1"

        let like = LikeRecordMapper.like(from: record)

        XCTAssertNil(like)
    }

    func test_roundTrip_preservesData() {
        let original = EncounterLike(
            id: "abc_like_xyz",
            encounterRecordName: "xyz",
            userID: "abc",
            createdAt: Date()
        )

        let record = LikeRecordMapper.record(from: original)
        let restored = LikeRecordMapper.like(from: record)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored?.id, original.id)
        XCTAssertEqual(restored?.encounterRecordName, original.encounterRecordName)
        XCTAssertEqual(restored?.userID, original.userID)
    }
}
