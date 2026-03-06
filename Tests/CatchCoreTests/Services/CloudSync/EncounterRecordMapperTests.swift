import XCTest
import CloudKit
@testable import CatchCore

@MainActor
final class EncounterRecordMapperTests: XCTestCase {

    // MARK: - Record Creation

    func test_record_setsCatReference() {
        let payload = makePayload(catRecordName: "cat-123")
        let recordID = CKRecord.ID(recordName: "enc-1")

        let record = EncounterRecordMapper.record(
            from: payload, ownerID: "user-1", existingRecord: nil, recordID: recordID
        )

        let ref = record[EncounterRecordMapper.catReferenceKey] as? CKRecord.Reference
        XCTAssertNotNil(ref)
        XCTAssertEqual(ref?.recordID.recordName, "cat-123")
        XCTAssertEqual(ref?.action, .deleteSelf)
    }

    func test_record_keepsStringFKForBackwardsCompatibility() {
        let payload = makePayload(catRecordName: "cat-abc")
        let recordID = CKRecord.ID(recordName: "enc-2")

        let record = EncounterRecordMapper.record(
            from: payload, ownerID: "user-1", existingRecord: nil, recordID: recordID
        )

        XCTAssertEqual(record["catRecordName"] as? String, "cat-abc")
    }

    func test_record_setsAllFields() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-1",
            date: date,
            locationName: "Central Park",
            locationLatitude: 40.785,
            locationLongitude: -73.968,
            notes: "friendly cat",
            photos: []
        )
        let recordID = CKRecord.ID(recordName: "enc-3")

        let record = EncounterRecordMapper.record(
            from: payload, ownerID: "owner-1", existingRecord: nil, recordID: recordID
        )

        XCTAssertEqual(record["ownerID"] as? String, "owner-1")
        XCTAssertEqual(record["catRecordName"] as? String, "cat-1")
        XCTAssertEqual(record["date"] as? Date, date)
        XCTAssertEqual(record["locationName"] as? String, "Central Park")
        XCTAssertEqual(record["locationLatitude"] as? Double, 40.785)
        XCTAssertEqual(record["locationLongitude"] as? Double, -73.968)
        XCTAssertEqual(record["notes"] as? String, "friendly cat")
    }

    // MARK: - Parsing

    func test_cloudEncounter_prefersReferenceOverStringFK() {
        let record = CKRecord(recordType: "Encounter", recordID: CKRecord.ID(recordName: "enc-1"))
        record["ownerID"] = "user-1"
        record["catRecordName"] = "old-cat"
        record["date"] = Date()

        let refRecordID = CKRecord.ID(recordName: "new-cat")
        record[EncounterRecordMapper.catReferenceKey] = CKRecord.Reference(recordID: refRecordID, action: .deleteSelf)

        let encounter = EncounterRecordMapper.cloudEncounter(from: record, photos: [])

        XCTAssertEqual(encounter?.catRecordName, "new-cat")
    }

    func test_cloudEncounter_fallsBackToStringFK() {
        let record = CKRecord(recordType: "Encounter", recordID: CKRecord.ID(recordName: "enc-2"))
        record["ownerID"] = "user-1"
        record["catRecordName"] = "legacy-cat"
        record["date"] = Date()

        let encounter = EncounterRecordMapper.cloudEncounter(from: record, photos: [])

        XCTAssertEqual(encounter?.catRecordName, "legacy-cat")
    }

    func test_cloudEncounter_returnsNilForMissingOwner() {
        let record = CKRecord(recordType: "Encounter")
        record["catRecordName"] = "cat-1"
        record["date"] = Date()

        XCTAssertNil(EncounterRecordMapper.cloudEncounter(from: record, photos: []))
    }

    func test_cloudEncounter_returnsNilForMissingCat() {
        let record = CKRecord(recordType: "Encounter")
        record["ownerID"] = "user-1"
        record["date"] = Date()

        XCTAssertNil(EncounterRecordMapper.cloudEncounter(from: record, photos: []))
    }

    func test_cloudEncounter_returnsNilForMissingDate() {
        let record = CKRecord(recordType: "Encounter")
        record["ownerID"] = "user-1"
        record["catRecordName"] = "cat-1"

        XCTAssertNil(EncounterRecordMapper.cloudEncounter(from: record, photos: []))
    }

    func test_roundTrip_preservesData() {
        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-rt",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            locationName: "Park",
            locationLatitude: 40.0,
            locationLongitude: -73.0,
            notes: "test",
            photos: []
        )
        let recordID = CKRecord.ID(recordName: "enc-rt")

        let record = EncounterRecordMapper.record(
            from: payload, ownerID: "owner-rt", existingRecord: nil, recordID: recordID
        )
        let encounter = EncounterRecordMapper.cloudEncounter(from: record, photos: [])

        XCTAssertNotNil(encounter)
        XCTAssertEqual(encounter?.catRecordName, "cat-rt")
        XCTAssertEqual(encounter?.ownerID, "owner-rt")
        XCTAssertEqual(encounter?.locationName, "Park")
    }

    // MARK: - Helpers

    private func makePayload(catRecordName: String) -> EncounterSyncPayload {
        EncounterSyncPayload(
            recordName: nil,
            catRecordName: catRecordName,
            date: Date(),
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )
    }
}
