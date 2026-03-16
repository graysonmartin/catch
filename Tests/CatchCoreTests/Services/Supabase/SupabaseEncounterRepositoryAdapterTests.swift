import XCTest
@testable import CatchCore

@MainActor
final class SupabaseEncounterRepositoryAdapterTests: XCTestCase {

    private var mockRepo: MockSupabaseEncounterRepository!
    private var adapter: SupabaseEncounterRepositoryAdapter!

    override func setUp() {
        super.setUp()
        mockRepo = MockSupabaseEncounterRepository()
        adapter = SupabaseEncounterRepositoryAdapter(repository: mockRepo)
    }

    override func tearDown() {
        mockRepo = nil
        adapter = nil
        super.tearDown()
    }

    // MARK: - save (insert)

    func testSaveWithoutRecordNameInsertsNewEncounter() async throws {
        let insertedEncounter = SupabaseEncounter.fixture()
        mockRepo.insertEncounterResult = insertedEncounter

        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-1",
            date: Date(),
            locationName: "park",
            locationLatitude: 37.0,
            locationLongitude: -122.0,
            notes: "spotted napping",
            photos: []
        )

        let result = try await adapter.save(payload, ownerID: "owner-1")

        XCTAssertEqual(result, insertedEncounter.id.uuidString)
        XCTAssertEqual(mockRepo.insertEncounterCalls.count, 1)
        XCTAssertEqual(mockRepo.insertEncounterCalls.first?.ownerID, "owner-1")
        XCTAssertEqual(mockRepo.insertEncounterCalls.first?.catID, "cat-1")
        XCTAssertTrue(mockRepo.updateEncounterCalls.isEmpty)
    }

    // MARK: - save (update)

    func testSaveWithRecordNameUpdatesExistingEncounter() async throws {
        let updatedEncounter = SupabaseEncounter.fixture(
            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
        )
        mockRepo.updateEncounterResult = updatedEncounter

        let payload = EncounterSyncPayload(
            recordName: "550e8400-e29b-41d4-a716-446655440000",
            catRecordName: "cat-1",
            date: Date(),
            locationName: "garden",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "updated",
            photos: []
        )

        let result = try await adapter.save(payload, ownerID: "owner-1")

        XCTAssertEqual(result, updatedEncounter.id.uuidString)
        XCTAssertEqual(mockRepo.updateEncounterCalls.count, 1)
        XCTAssertEqual(mockRepo.updateEncounterCalls.first?.id, "550e8400-e29b-41d4-a716-446655440000")
        XCTAssertTrue(mockRepo.insertEncounterCalls.isEmpty)
    }

    // MARK: - delete

    func testDeleteCallsRepository() async throws {
        try await adapter.delete(recordName: "enc-to-delete")

        XCTAssertEqual(mockRepo.deleteEncounterCalls, ["enc-to-delete"])
    }

    // MARK: - fetchAll

    func testFetchAllReturnsCloudEncounters() async throws {
        let ownerID = UUID()
        let enc1 = SupabaseEncounter.fixture(ownerID: ownerID, notes: "first")
        let enc2 = SupabaseEncounter.fixture(ownerID: ownerID, notes: "second")
        mockRepo.fetchEncountersResult = [enc1, enc2]

        let results = try await adapter.fetchAll(ownerID: ownerID.uuidString)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].notes, "first")
        XCTAssertEqual(results[1].notes, "second")
        XCTAssertEqual(mockRepo.fetchEncountersByOwnerCalls, [ownerID.uuidString])
    }

    func testFetchAllReturnsEmptyForNoResults() async throws {
        mockRepo.fetchEncountersResult = []

        let results = try await adapter.fetchAll(ownerID: "no-encounters")

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Error propagation

    func testSavePropagatesToInsertError() async {
        let expectedError = NSError(domain: "test", code: 42)
        mockRepo.errorToThrow = expectedError

        let payload = EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-1",
            date: Date(),
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            photos: []
        )

        do {
            _ = try await adapter.save(payload, ownerID: "owner")
            XCTFail("expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 42)
        }
    }

    func testDeletePropagatesError() async {
        let expectedError = NSError(domain: "test", code: 99)
        mockRepo.errorToThrow = expectedError

        do {
            try await adapter.delete(recordName: "fail")
            XCTFail("expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 99)
        }
    }

    func testFetchAllPropagatesError() async {
        let expectedError = NSError(domain: "test", code: 77)
        mockRepo.errorToThrow = expectedError

        do {
            _ = try await adapter.fetchAll(ownerID: "fail")
            XCTFail("expected error")
        } catch {
            XCTAssertEqual((error as NSError).code, 77)
        }
    }
}
