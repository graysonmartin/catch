import XCTest
import SwiftData
import CatchCore

@MainActor
final class CKCatSyncServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var mockCatRepo: MockCatRepository!
    private var mockEncRepo: MockEncounterRepository!
    private var userID: String?

    override func setUp() async throws {
        container = try ModelContainer.forTesting()
        context = container.mainContext
        mockCatRepo = MockCatRepository()
        mockEncRepo = MockEncounterRepository()
        userID = "test-user-123"
    }

    private func makeSUT() -> CKCatSyncService {
        let id = userID
        return CKCatSyncService(
            catRepository: mockCatRepo,
            encounterRepository: mockEncRepo,
            getUserID: { id }
        )
    }

    // MARK: - syncNewCat

    func test_syncNewCat_propagatesBreedInPayload() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Fancy", breed: "Persian", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewCat(cat, firstEncounter: encounter)

        XCTAssertEqual(mockCatRepo.saveCalls.count, 1)
        XCTAssertEqual(mockCatRepo.saveCalls[0].payload.breed, "Persian")
    }

    func test_syncNewCat_savesCatThenEncounterSequentially() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Mochi", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewCat(cat, firstEncounter: encounter)

        XCTAssertEqual(mockCatRepo.saveCalls.count, 1)
        XCTAssertEqual(mockCatRepo.saveCalls[0].payload.name, "Mochi")
        XCTAssertEqual(mockCatRepo.saveCalls[0].ownerID, "test-user-123")

        XCTAssertEqual(mockEncRepo.saveCalls.count, 1)
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.catRecordName, "mock-cat-record")
        XCTAssertEqual(mockEncRepo.saveCalls[0].ownerID, "test-user-123")

        XCTAssertEqual(cat.cloudKitRecordName, "mock-cat-record")
        XCTAssertEqual(encounter.cloudKitRecordName, "mock-enc-record")
    }

    func test_syncNewCat_whenNotSignedIn_noRepoCalls() async {
        userID = nil
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Ghost", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewCat(cat, firstEncounter: encounter)

        XCTAssertTrue(mockCatRepo.saveCalls.isEmpty)
        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
        XCTAssertNil(cat.cloudKitRecordName)
    }

    func test_syncNewCat_whenCatSaveFails_encounterNotAttempted() async {
        mockCatRepo.saveResult = .failure(CloudSyncError.uploadFailed)
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Fail", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewCat(cat, firstEncounter: encounter)

        XCTAssertEqual(mockCatRepo.saveCalls.count, 1)
        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
        XCTAssertNil(cat.cloudKitRecordName)
        XCTAssertNil(encounter.cloudKitRecordName)
    }

    // MARK: - syncCatUpdate

    func test_syncCatUpdate_syncsWhenRecordNameExists() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Patches", cloudKitRecordName: "existing-rec", in: context)

        await sut.syncCatUpdate(cat)

        XCTAssertEqual(mockCatRepo.saveCalls.count, 1)
        XCTAssertEqual(mockCatRepo.saveCalls[0].payload.recordName, "existing-rec")
    }

    func test_syncCatUpdate_whenNoRecordName_noOps() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "NoRecord", in: context)

        await sut.syncCatUpdate(cat)

        XCTAssertTrue(mockCatRepo.saveCalls.isEmpty)
    }

    // MARK: - Delete

    func test_deleteCat_delegatesToRepository() async throws {
        let sut = makeSUT()

        try await sut.deleteCat(recordName: "cat-to-delete")

        XCTAssertEqual(mockCatRepo.deleteCalls, ["cat-to-delete"])
    }

    func test_syncNewCat_handlesNilName() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: nil, in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewCat(cat, firstEncounter: encounter)

        XCTAssertEqual(mockCatRepo.saveCalls.count, 1)
        XCTAssertNil(mockCatRepo.saveCalls[0].payload.name)
    }

    // MARK: - isSyncing

    func test_isSyncing_isFalseAfterSync() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Sync", cloudKitRecordName: "rec", in: context)

        XCTAssertFalse(sut.isSyncing)
        await sut.syncCatUpdate(cat)
        XCTAssertFalse(sut.isSyncing)
    }
}
