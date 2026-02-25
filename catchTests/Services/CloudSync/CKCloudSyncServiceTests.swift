import XCTest
import SwiftData

@MainActor
final class CKCloudSyncServiceTests: XCTestCase {

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

    private func makeSUT() -> CKCloudSyncService {
        let id = userID
        return CKCloudSyncService(
            catRepository: mockCatRepo,
            encounterRepository: mockEncRepo,
            getUserID: { id }
        )
    }

    // MARK: - syncNewCat

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

    // MARK: - syncNewEncounter

    func test_syncNewEncounter_syncsWhenCatHasRecordName() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Biscuit", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewEncounter(encounter, for: cat)

        XCTAssertEqual(mockEncRepo.saveCalls.count, 1)
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.catRecordName, "cat-rec")
        XCTAssertEqual(encounter.cloudKitRecordName, "mock-enc-record")
    }

    func test_syncNewEncounter_whenCatHasNoRecordName_noOps() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Unsaved", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncNewEncounter(encounter, for: cat)

        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
        XCTAssertNil(encounter.cloudKitRecordName)
    }

    // MARK: - syncEncounterUpdate

    func test_syncEncounterUpdate_syncsWhenBothRecordNamesExist() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Luna", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, cloudKitRecordName: "enc-rec", in: context)

        await sut.syncEncounterUpdate(encounter)

        XCTAssertEqual(mockEncRepo.saveCalls.count, 1)
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.recordName, "enc-rec")
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.catRecordName, "cat-rec")
    }

    func test_syncEncounterUpdate_whenNoEncounterRecordName_noOps() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Luna", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        await sut.syncEncounterUpdate(encounter)

        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
    }

    // MARK: - Delete

    func test_deleteCat_delegatesToRepository() async throws {
        let sut = makeSUT()

        try await sut.deleteCat(recordName: "cat-to-delete")

        XCTAssertEqual(mockCatRepo.deleteCalls, ["cat-to-delete"])
    }

    func test_deleteEncounter_delegatesToRepository() async throws {
        let sut = makeSUT()

        try await sut.deleteEncounter(recordName: "enc-to-delete")

        XCTAssertEqual(mockEncRepo.deleteCalls, ["enc-to-delete"])
    }

    // MARK: - isSyncing

    func test_isSyncing_isTrueWhileSyncing() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Sync", cloudKitRecordName: "rec", in: context)

        XCTAssertFalse(sut.isSyncing)
        await sut.syncCatUpdate(cat)
        XCTAssertFalse(sut.isSyncing)
    }
}
