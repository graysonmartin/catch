import XCTest
import SwiftData
import CatchCore

@MainActor
final class CKEncounterSyncServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var mockEncRepo: MockEncounterRepository!
    private var userID: String?

    override func setUp() async throws {
        container = try ModelContainer.forTesting()
        context = container.mainContext
        mockEncRepo = MockEncounterRepository()
        userID = "test-user-123"
    }

    private func makeSUT() -> CKEncounterSyncService {
        let id = userID
        return CKEncounterSyncService(
            encounterRepository: mockEncRepo,
            getUserID: { id }
        )
    }

    // MARK: - syncNewEncounter

    func test_syncNewEncounter_syncsWhenCatHasRecordName() async throws {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Biscuit", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        try await sut.syncNewEncounter(encounter, for: cat)

        XCTAssertEqual(mockEncRepo.saveCalls.count, 1)
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.catRecordName, "cat-rec")
        XCTAssertEqual(encounter.cloudKitRecordName, "mock-enc-record")
    }

    func test_syncNewEncounter_whenCatHasNoRecordName_throwsRecordNotFound() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Unsaved", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        do {
            try await sut.syncNewEncounter(encounter, for: cat)
            XCTFail("Expected CloudSyncError.recordNotFound")
        } catch {
            XCTAssertEqual(error as? CloudSyncError, .recordNotFound)
        }

        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
        XCTAssertNil(encounter.cloudKitRecordName)
    }

    func test_syncNewEncounter_whenNotSignedIn_throwsNotSignedIn() async {
        userID = nil
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Biscuit", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        do {
            try await sut.syncNewEncounter(encounter, for: cat)
            XCTFail("Expected CloudSyncError.notSignedIn")
        } catch {
            XCTAssertEqual(error as? CloudSyncError, .notSignedIn)
        }

        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
    }

    func test_syncNewEncounter_whenSaveFails_propagatesError() async {
        mockEncRepo.saveResult = .failure(CloudSyncError.uploadFailed)
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Biscuit", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        do {
            try await sut.syncNewEncounter(encounter, for: cat)
            XCTFail("Expected CloudSyncError.uploadFailed")
        } catch {
            XCTAssertEqual(error as? CloudSyncError, .uploadFailed)
        }

        XCTAssertNil(encounter.cloudKitRecordName)
    }

    // MARK: - syncEncounterUpdate

    func test_syncEncounterUpdate_syncsWhenBothRecordNamesExist() async throws {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Luna", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, cloudKitRecordName: "enc-rec", in: context)

        try await sut.syncEncounterUpdate(encounter)

        XCTAssertEqual(mockEncRepo.saveCalls.count, 1)
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.recordName, "enc-rec")
        XCTAssertEqual(mockEncRepo.saveCalls[0].payload.catRecordName, "cat-rec")
    }

    func test_syncEncounterUpdate_whenNoEncounterRecordName_throwsRecordNotFound() async {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Luna", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        do {
            try await sut.syncEncounterUpdate(encounter)
            XCTFail("Expected CloudSyncError.recordNotFound")
        } catch {
            XCTAssertEqual(error as? CloudSyncError, .recordNotFound)
        }

        XCTAssertTrue(mockEncRepo.saveCalls.isEmpty)
    }

    // MARK: - Delete

    func test_deleteEncounter_delegatesToRepository() async throws {
        let sut = makeSUT()

        try await sut.deleteEncounter(recordName: "enc-to-delete")

        XCTAssertEqual(mockEncRepo.deleteCalls, ["enc-to-delete"])
    }

    // MARK: - isSyncing

    func test_isSyncing_isFalseAfterSync() async throws {
        let sut = makeSUT()
        let cat = Fixtures.cat(name: "Biscuit", cloudKitRecordName: "cat-rec", in: context)
        let encounter = Fixtures.encounter(for: cat, in: context)

        XCTAssertFalse(sut.isSyncing)
        try await sut.syncNewEncounter(encounter, for: cat)
        XCTAssertFalse(sut.isSyncing)
    }
}
