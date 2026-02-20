import XCTest

@MainActor
final class MockCatSyncServiceTests: XCTestCase {

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

    private func makeEncounterPayload() -> EncounterSyncPayload {
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

    // MARK: - saveCat

    func test_saveCat_tracksCallAndReturnsRecordName() async throws {
        let mock = MockCatSyncService()
        let payload = makePayload()
        let result = try await mock.saveCat(payload, ownerID: "user-1")

        XCTAssertEqual(mock.saveCatCalls.count, 1)
        XCTAssertEqual(mock.saveCatCalls[0].ownerID, "user-1")
        XCTAssertEqual(mock.saveCatCalls[0].payload.name, "Test Cat")
        XCTAssertEqual(result, "mock-cat-record")
    }

    func test_saveCat_throwsWhenErrorSet() async {
        let mock = MockCatSyncService()
        mock.saveCatResult = .failure(CatSyncServiceError.uploadFailed)

        do {
            _ = try await mock.saveCat(makePayload(), ownerID: "user-1")
            XCTFail("Expected error")
        } catch let error as CatSyncServiceError {
            XCTAssertEqual(error, .uploadFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - saveEncounter

    func test_saveEncounter_tracksCallAndReturnsRecordName() async throws {
        let mock = MockCatSyncService()
        let payload = makeEncounterPayload()
        let result = try await mock.saveEncounter(payload, ownerID: "user-1")

        XCTAssertEqual(mock.saveEncounterCalls.count, 1)
        XCTAssertEqual(mock.saveEncounterCalls[0].payload.catRecordName, "cat-123")
        XCTAssertEqual(result, "mock-enc-record")
    }

    func test_saveEncounter_throwsWhenErrorSet() async {
        let mock = MockCatSyncService()
        mock.saveEncounterResult = .failure(CatSyncServiceError.notSignedIn)

        do {
            _ = try await mock.saveEncounter(makeEncounterPayload(), ownerID: "user-1")
            XCTFail("Expected error")
        } catch let error as CatSyncServiceError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - deleteCat

    func test_deleteCat_tracksCall() async throws {
        let mock = MockCatSyncService()
        try await mock.deleteCat(recordName: "cat-record-1")

        XCTAssertEqual(mock.deleteCatCalls, ["cat-record-1"])
    }

    func test_deleteCat_throwsWhenErrorSet() async {
        let mock = MockCatSyncService()
        mock.deleteCatError = CatSyncServiceError.recordNotFound

        do {
            try await mock.deleteCat(recordName: "nope")
            XCTFail("Expected error")
        } catch let error as CatSyncServiceError {
            XCTAssertEqual(error, .recordNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - deleteEncounter

    func test_deleteEncounter_tracksCall() async throws {
        let mock = MockCatSyncService()
        try await mock.deleteEncounter(recordName: "enc-record-1")

        XCTAssertEqual(mock.deleteEncounterCalls, ["enc-record-1"])
    }

    // MARK: - fetchCats

    func test_fetchCats_tracksCallAndReturnsResult() async throws {
        let mock = MockCatSyncService()
        mock.fetchCatsResult = [
            CloudCat(
                recordName: "r1", ownerID: "u1", name: "Whiskers",
                estimatedAge: "", locationName: "", locationLatitude: nil,
                locationLongitude: nil, notes: "", isOwned: false,
                createdAt: Date(), photos: []
            )
        ]

        let result = try await mock.fetchCats(ownerID: "u1")

        XCTAssertEqual(mock.fetchCatsCalls, ["u1"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "Whiskers")
    }

    func test_fetchCats_throwsWhenErrorSet() async {
        let mock = MockCatSyncService()
        mock.fetchCatsError = CatSyncServiceError.fetchFailed

        do {
            _ = try await mock.fetchCats(ownerID: "u1")
            XCTFail("Expected error")
        } catch let error as CatSyncServiceError {
            XCTAssertEqual(error, .fetchFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - fetchEncounters

    func test_fetchEncounters_tracksCallAndReturnsResult() async throws {
        let mock = MockCatSyncService()
        mock.fetchEncountersResult = [
            CloudEncounter(
                recordName: "e1", ownerID: "u1", catRecordName: "c1",
                date: Date(), locationName: "", locationLatitude: nil,
                locationLongitude: nil, notes: "hi", photos: []
            )
        ]

        let result = try await mock.fetchEncounters(ownerID: "u1")

        XCTAssertEqual(mock.fetchEncountersCalls, ["u1"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].notes, "hi")
    }

    // MARK: - reset

    func test_reset_clearsEverything() async throws {
        let mock = MockCatSyncService()
        _ = try await mock.saveCat(makePayload(), ownerID: "u1")
        _ = try await mock.saveEncounter(makeEncounterPayload(), ownerID: "u1")
        try await mock.deleteCat(recordName: "r1")
        mock.saveCatResult = .failure(CatSyncServiceError.uploadFailed)

        mock.reset()

        XCTAssertTrue(mock.saveCatCalls.isEmpty)
        XCTAssertTrue(mock.saveEncounterCalls.isEmpty)
        XCTAssertTrue(mock.deleteCatCalls.isEmpty)
        XCTAssertEqual(try mock.saveCatResult.get(), "mock-cat-record")
    }
}
