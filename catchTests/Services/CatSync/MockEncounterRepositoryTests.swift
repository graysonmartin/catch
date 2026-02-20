import XCTest

@MainActor
final class MockEncounterRepositoryTests: XCTestCase {

    private func makePayload() -> EncounterSyncPayload {
        EncounterSyncPayload(
            recordName: nil,
            catRecordName: "cat-123",
            date: Date(),
            locationName: "Alley",
            locationLatitude: 37.0,
            locationLongitude: -122.0,
            notes: "spotted again",
            photos: []
        )
    }

    // MARK: - save

    func test_save_tracksCallAndReturnsRecordName() async throws {
        let mock = MockEncounterRepository()
        let payload = makePayload()
        let result = try await mock.save(payload, ownerID: "user-1")

        XCTAssertEqual(mock.saveCalls.count, 1)
        XCTAssertEqual(mock.saveCalls[0].payload.catRecordName, "cat-123")
        XCTAssertEqual(result, "mock-enc-record")
    }

    func test_save_throwsWhenErrorSet() async {
        let mock = MockEncounterRepository()
        mock.saveResult = .failure(CatSyncServiceError.notSignedIn)

        do {
            _ = try await mock.save(makePayload(), ownerID: "user-1")
            XCTFail("Expected error")
        } catch let error as CatSyncServiceError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - delete

    func test_delete_tracksCall() async throws {
        let mock = MockEncounterRepository()
        try await mock.delete(recordName: "enc-record-1")

        XCTAssertEqual(mock.deleteCalls, ["enc-record-1"])
    }

    // MARK: - fetchAll

    func test_fetchAll_tracksCallAndReturnsResult() async throws {
        let mock = MockEncounterRepository()
        mock.fetchAllResult = [
            CloudEncounter(
                recordName: "e1", ownerID: "u1", catRecordName: "c1",
                date: Date(), locationName: "", locationLatitude: nil,
                locationLongitude: nil, notes: "hi", photos: []
            )
        ]

        let result = try await mock.fetchAll(ownerID: "u1")

        XCTAssertEqual(mock.fetchAllCalls, ["u1"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].notes, "hi")
    }

    // MARK: - reset

    func test_reset_clearsEverything() async throws {
        let mock = MockEncounterRepository()
        _ = try await mock.save(makePayload(), ownerID: "u1")
        mock.saveResult = .failure(CatSyncServiceError.uploadFailed)

        mock.reset()

        XCTAssertTrue(mock.saveCalls.isEmpty)
        XCTAssertTrue(mock.deleteCalls.isEmpty)
        XCTAssertTrue(mock.fetchAllCalls.isEmpty)
        XCTAssertEqual(try mock.saveResult.get(), "mock-enc-record")
    }
}
