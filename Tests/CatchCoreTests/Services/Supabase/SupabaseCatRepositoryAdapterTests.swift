import XCTest
@testable import CatchCore

@MainActor
final class SupabaseCatRepositoryAdapterTests: XCTestCase {

    private var mockRepo: MockSupabaseCatRepository!
    private var adapter: SupabaseCatRepositoryAdapter!

    override func setUp() {
        super.setUp()
        mockRepo = MockSupabaseCatRepository()
        adapter = SupabaseCatRepositoryAdapter(repository: mockRepo)
    }

    override func tearDown() {
        mockRepo = nil
        adapter = nil
        super.tearDown()
    }

    // MARK: - save (insert)

    func testSaveWithoutRecordNameInsertsNewCat() async throws {
        let insertedCat = SupabaseCat.fixture()
        mockRepo.insertCatResult = insertedCat

        let payload = CatSyncPayload(
            recordName: nil,
            name: "whiskers",
            breed: "tabby",
            estimatedAge: "2 years",
            locationName: "park",
            locationLatitude: 37.0,
            locationLongitude: -122.0,
            notes: "friendly",
            isOwned: false,
            createdAt: Date(),
            photos: []
        )

        let result = try await adapter.save(payload, ownerID: "owner-1")

        XCTAssertEqual(result, insertedCat.id.uuidString)
        XCTAssertEqual(mockRepo.insertCatCalls.count, 1)
        XCTAssertEqual(mockRepo.insertCatCalls.first?.ownerID, "owner-1")
        XCTAssertEqual(mockRepo.insertCatCalls.first?.name, "whiskers")
        XCTAssertTrue(mockRepo.updateCatCalls.isEmpty)
    }

    // MARK: - save (update)

    func testSaveWithRecordNameUpdatesExistingCat() async throws {
        let updatedCat = SupabaseCat.fixture(id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!)
        mockRepo.updateCatResult = updatedCat

        let payload = CatSyncPayload(
            recordName: "550e8400-e29b-41d4-a716-446655440000",
            name: "new name",
            breed: "persian",
            estimatedAge: "3 years",
            locationName: "garden",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: true,
            createdAt: Date(),
            photos: []
        )

        let result = try await adapter.save(payload, ownerID: "owner-1")

        XCTAssertEqual(result, updatedCat.id.uuidString)
        XCTAssertEqual(mockRepo.updateCatCalls.count, 1)
        XCTAssertEqual(mockRepo.updateCatCalls.first?.id, "550e8400-e29b-41d4-a716-446655440000")
        XCTAssertEqual(mockRepo.updateCatCalls.first?.payload.name, "new name")
        XCTAssertTrue(mockRepo.insertCatCalls.isEmpty)
    }

    // MARK: - delete

    func testDeleteCallsRepository() async throws {
        try await adapter.delete(recordName: "cat-to-delete")

        XCTAssertEqual(mockRepo.deleteCatCalls, ["cat-to-delete"])
    }

    // MARK: - fetchAll

    func testFetchAllReturnsCloudCats() async throws {
        let ownerID = UUID()
        let cat1 = SupabaseCat.fixture(ownerID: ownerID, name: "cat 1")
        let cat2 = SupabaseCat.fixture(ownerID: ownerID, name: "cat 2")
        mockRepo.fetchCatsResult = [cat1, cat2]

        let results = try await adapter.fetchAll(ownerID: ownerID.uuidString)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "cat 1")
        XCTAssertEqual(results[1].name, "cat 2")
        XCTAssertEqual(mockRepo.fetchCatsCalls, [ownerID.uuidString])
    }

    func testFetchAllReturnsEmptyForNoResults() async throws {
        mockRepo.fetchCatsResult = []

        let results = try await adapter.fetchAll(ownerID: "no-cats")

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Error propagation

    func testSavePropagatesToInsertError() async {
        let expectedError = NSError(domain: "test", code: 42)
        mockRepo.errorToThrow = expectedError

        let payload = CatSyncPayload(
            recordName: nil,
            name: "fail",
            breed: nil,
            estimatedAge: "",
            locationName: "",
            locationLatitude: nil,
            locationLongitude: nil,
            notes: "",
            isOwned: false,
            createdAt: Date(),
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
