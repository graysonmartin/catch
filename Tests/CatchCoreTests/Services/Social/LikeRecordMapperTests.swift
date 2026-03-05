import XCTest
import CloudKit
@testable import CatchCore

@MainActor
final class LikeRecordMapperTests: XCTestCase {

    // MARK: - Record Creation

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

    func test_recordFromLike_setsEncounterReference() {
        let like = EncounterLike(
            id: "user1_like_enc1",
            encounterRecordName: "enc1",
            userID: "user1",
            createdAt: Date()
        )

        let record = LikeRecordMapper.record(from: like)

        let ref = record[LikeRecordMapper.encounterReferenceKey] as? CKRecord.Reference
        XCTAssertNotNil(ref)
        XCTAssertEqual(ref?.recordID.recordName, "enc1")
        XCTAssertEqual(ref?.action, .deleteSelf)
    }

    // MARK: - Parsing

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

    func test_likeFromRecord_prefersReferenceOverStringFK() {
        let recordID = CKRecord.ID(recordName: "like-1")
        let record = CKRecord(recordType: "EncounterLike", recordID: recordID)
        record["encounterRecordName"] = "old-enc"
        record["userID"] = "user1"

        let refID = CKRecord.ID(recordName: "new-enc")
        record[LikeRecordMapper.encounterReferenceKey] = CKRecord.Reference(recordID: refID, action: .deleteSelf)

        let like = LikeRecordMapper.like(from: record)

        XCTAssertEqual(like?.encounterRecordName, "new-enc")
    }

    func test_likeFromRecord_fallsBackToStringFK() {
        let recordID = CKRecord.ID(recordName: "like-2")
        let record = CKRecord(recordType: "EncounterLike", recordID: recordID)
        record["encounterRecordName"] = "legacy-enc"
        record["userID"] = "user1"

        let like = LikeRecordMapper.like(from: record)

        XCTAssertEqual(like?.encounterRecordName, "legacy-enc")
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

    // MARK: - hasReference

    func test_hasReference_returnsTrueWhenReferenceExists() {
        let record = CKRecord(recordType: "EncounterLike")
        let refID = CKRecord.ID(recordName: "enc-1")
        record[LikeRecordMapper.encounterReferenceKey] = CKRecord.Reference(recordID: refID, action: .deleteSelf)

        XCTAssertTrue(LikeRecordMapper.hasReference(record))
    }

    func test_hasReference_returnsFalseWhenNoReference() {
        let record = CKRecord(recordType: "EncounterLike")
        record["encounterRecordName"] = "enc-1"

        XCTAssertFalse(LikeRecordMapper.hasReference(record))
    }

    // MARK: - Backfill

    func test_backfillReference_addsReferenceFromStringFK() {
        let record = CKRecord(recordType: "EncounterLike")
        record["encounterRecordName"] = "enc-backfill"

        let updated = LikeRecordMapper.backfillReference(on: record)

        XCTAssertNotNil(updated)
        let ref = updated?[LikeRecordMapper.encounterReferenceKey] as? CKRecord.Reference
        XCTAssertEqual(ref?.recordID.recordName, "enc-backfill")
        XCTAssertEqual(ref?.action, .deleteSelf)
    }

    func test_backfillReference_returnsNilWhenAlreadyBackfilled() {
        let record = CKRecord(recordType: "EncounterLike")
        record["encounterRecordName"] = "enc-1"
        let refID = CKRecord.ID(recordName: "enc-1")
        record[LikeRecordMapper.encounterReferenceKey] = CKRecord.Reference(recordID: refID, action: .deleteSelf)

        XCTAssertNil(LikeRecordMapper.backfillReference(on: record))
    }

    func test_backfillReference_returnsNilWhenNoStringFK() {
        let record = CKRecord(recordType: "EncounterLike")

        XCTAssertNil(LikeRecordMapper.backfillReference(on: record))
    }

    func test_backfillReference_returnsNilForEmptyStringFK() {
        let record = CKRecord(recordType: "EncounterLike")
        record["encounterRecordName"] = ""

        XCTAssertNil(LikeRecordMapper.backfillReference(on: record))
    }
}
