import XCTest
@testable import CatchCore

@MainActor
final class SupabaseBlockServiceTests: XCTestCase {

    private var repository: MockBlockRepository!
    private var rateLimiter: MockRateLimiter!
    private var service: SupabaseBlockService!
    private let currentUserID = "user-123"

    override func setUp() {
        super.setUp()
        repository = MockBlockRepository()
        rateLimiter = MockRateLimiter()
        service = SupabaseBlockService(
            repository: repository,
            getCurrentUserID: { [currentUserID] in currentUserID },
            rateLimiter: rateLimiter
        )
    }

    override func tearDown() {
        repository = nil
        rateLimiter = nil
        service = nil
        super.tearDown()
    }

    // MARK: - blockUser

    func testBlockUserSucceeds() async throws {
        repository.insertBlockResult = .fixture()

        try await service.blockUser("target-456")

        XCTAssertEqual(repository.insertBlockCalls.count, 1)
        XCTAssertEqual(repository.insertBlockCalls.first?.blockerID, currentUserID)
        XCTAssertEqual(repository.insertBlockCalls.first?.blockedID, "target-456")
        XCTAssertTrue(service.isBlocked("target-456"))
        XCTAssertTrue(service.blockedUserIDs.contains("target-456"))
    }

    func testBlockUserNotSignedInThrows() async {
        let sut = SupabaseBlockService(
            repository: repository,
            getCurrentUserID: { nil },
            rateLimiter: rateLimiter
        )

        do {
            try await sut.blockUser("target-456")
            XCTFail("Expected BlockError.notSignedIn")
        } catch let error as BlockError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repository.insertBlockCalls.count, 0)
    }

    func testBlockUserCannotBlockSelfThrows() async {
        do {
            try await service.blockUser(currentUserID)
            XCTFail("Expected BlockError.cannotBlockSelf")
        } catch let error as BlockError {
            XCTAssertEqual(error, .cannotBlockSelf)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repository.insertBlockCalls.count, 0)
    }

    func testBlockUserAlreadyBlockedThrows() async throws {
        repository.insertBlockResult = .fixture()
        try await service.blockUser("target-456")

        do {
            try await service.blockUser("target-456")
            XCTFail("Expected BlockError.alreadyBlocked")
        } catch let error as BlockError {
            XCTAssertEqual(error, .alreadyBlocked)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repository.insertBlockCalls.count, 1)
    }

    func testBlockUserRateLimitedThrows() async {
        rateLimiter.blockAction(.block)

        do {
            try await service.blockUser("target-456")
            XCTFail("Expected RateLimitError")
        } catch is RateLimitError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(repository.insertBlockCalls.count, 0)
    }

    func testBlockUserNetworkErrorThrows() async {
        repository.insertBlockError = NSError(
            domain: "net", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "timeout"]
        )

        do {
            try await service.blockUser("target-456")
            XCTFail("Expected BlockError.networkError")
        } catch let error as BlockError {
            if case .networkError(let message) = error {
                XCTAssertTrue(message.contains("timeout"))
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertFalse(service.isBlocked("target-456"))
    }

    func testBlockUserRecordsRateLimitAction() async throws {
        repository.insertBlockResult = .fixture()

        try await service.blockUser("target-456")

        XCTAssertEqual(rateLimiter.recordedActions, [.block])
    }

    // MARK: - unblockUser

    func testUnblockUserSucceeds() async throws {
        repository.insertBlockResult = .fixture()
        try await service.blockUser("target-456")
        XCTAssertTrue(service.isBlocked("target-456"))

        try await service.unblockUser("target-456")

        XCTAssertEqual(repository.deleteBlockCalls.count, 1)
        XCTAssertEqual(repository.deleteBlockCalls.first?.blockedID, "target-456")
        XCTAssertFalse(service.isBlocked("target-456"))
    }

    func testUnblockUserNotSignedInThrows() async {
        let sut = SupabaseBlockService(
            repository: repository,
            getCurrentUserID: { nil },
            rateLimiter: rateLimiter
        )

        do {
            try await sut.unblockUser("target-456")
            XCTFail("Expected BlockError.notSignedIn")
        } catch let error as BlockError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnblockUserRecordsRateLimitAction() async throws {
        try await service.unblockUser("target-456")

        XCTAssertEqual(rateLimiter.recordedActions, [.unblock])
    }

    // MARK: - loadBlocks

    func testLoadBlocksPopulatesBlockedUserIDs() async throws {
        let blockedID = UUID()
        repository.fetchBlocksResult = [
            .fixture(blockedID: blockedID)
        ]

        try await service.loadBlocks()

        XCTAssertEqual(repository.fetchBlocksCalls.count, 1)
        XCTAssertTrue(service.blockedUserIDs.contains(blockedID.uuidString.lowercased()))
    }

    func testLoadBlocksNotSignedInNoOp() async throws {
        let sut = SupabaseBlockService(
            repository: repository,
            getCurrentUserID: { nil },
            rateLimiter: rateLimiter
        )

        try await sut.loadBlocks()

        XCTAssertEqual(repository.fetchBlocksCalls.count, 0)
        XCTAssertTrue(sut.blockedUserIDs.isEmpty)
    }

    func testLoadBlocksNetworkErrorThrows() async {
        repository.fetchBlocksError = NSError(
            domain: "net", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "offline"]
        )

        do {
            try await service.loadBlocks()
            XCTFail("Expected BlockError.networkError")
        } catch let error as BlockError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - isBlocked

    func testIsBlockedReturnsFalseByDefault() {
        XCTAssertFalse(service.isBlocked("anyone"))
    }

    func testIsBlockedReturnsTrueAfterBlock() async throws {
        repository.insertBlockResult = .fixture()

        try await service.blockUser("target-456")

        XCTAssertTrue(service.isBlocked("target-456"))
    }

    func testIsBlockedReturnsFalseAfterUnblock() async throws {
        repository.insertBlockResult = .fixture()
        try await service.blockUser("target-456")

        try await service.unblockUser("target-456")

        XCTAssertFalse(service.isBlocked("target-456"))
    }
}
