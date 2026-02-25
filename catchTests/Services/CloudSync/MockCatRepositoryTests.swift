import XCTest

@MainActor
final class MockCatRepositoryTests: XCTestCase {

    private func makePayload() -> CatSyncPayload {
        CatSyncPayload(
            recordName: nil,
            name: "Test Cat",
            estimatedAge: "2 years",
            locationName: "Park",
            locationLatitude: 37.0,
            locationLongitude: -122.0,
            notes: "orange tabby",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )
    }

    // MARK: - save

    func test_save_tracksCallAndReturnsRecordName() async throws {
        let mock = MockCatRepository()
        let payload = makePayload()
        let result = try await mock.save(payload, ownerID: "user-1")

        XCTAssertEqual(mock.saveCalls.count, 1)
        XCTAssertEqual(mock.saveCalls[0].ownerID, "user-1")
        XCTAssertEqual(mock.saveCalls[0].payload.name, "Test Cat")
        XCTAssertEqual(result, "mock-cat-record")
    }

    func test_save_throwsWhenErrorSet() async {
        let mock = MockCatRepository()
        mock.saveResult = .failure(CloudSyncError.uploadFailed)

        do {
            _ = try await mock.save(makePayload(), ownerID: "user-1")
            XCTFail("Expected error")
        } catch let error as CloudSyncError {
            XCTAssertEqual(error, .uploadFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - delete

    func test_delete_tracksCall() async throws {
        let mock = MockCatRepository()
        try await mock.delete(recordName: "cat-record-1")

        XCTAssertEqual(mock.deleteCalls, ["cat-record-1"])
    }

    func test_delete_throwsWhenErrorSet() async {
        let mock = MockCatRepository()
        mock.deleteError = CloudSyncError.recordNotFound

        do {
            try await mock.delete(recordName: "nope")
            XCTFail("Expected error")
        } catch let error as CloudSyncError {
            XCTAssertEqual(error, .recordNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - fetchAll

    func test_fetchAll_tracksCallAndReturnsResult() async throws {
        let mock = MockCatRepository()
        mock.fetchAllResult = [
            CloudCat(
                recordName: "r1", ownerID: "u1", name: "Whiskers",
                estimatedAge: "", locationName: "", locationLatitude: nil,
                locationLongitude: nil, notes: "", isOwned: false,
                createdAt: Date(), photos: []
            )
        ]

        let result = try await mock.fetchAll(ownerID: "u1")

        XCTAssertEqual(mock.fetchAllCalls, ["u1"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Whiskers")
    }

    func test_fetchAll_throwsWhenErrorSet() async {
        let mock = MockCatRepository()
        mock.fetchAllError = CloudSyncError.fetchFailed

        do {
            _ = try await mock.fetchAll(ownerID: "u1")
            XCTFail("Expected error")
        } catch let error as CloudSyncError {
            XCTAssertEqual(error, .fetchFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - reset

    func test_reset_clearsEverything() async throws {
        let mock = MockCatRepository()
        _ = try await mock.save(makePayload(), ownerID: "u1")
        try await mock.delete(recordName: "r1")
        mock.saveResult = .failure(CloudSyncError.uploadFailed)

        mock.reset()

        XCTAssertTrue(mock.saveCalls.isEmpty)
        XCTAssertTrue(mock.deleteCalls.isEmpty)
        XCTAssertTrue(mock.fetchAllCalls.isEmpty)
        XCTAssertEqual(try mock.saveResult.get(), "mock-cat-record")
    }
}
