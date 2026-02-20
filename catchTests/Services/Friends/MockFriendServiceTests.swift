import XCTest

@MainActor
final class MockFriendServiceTests: XCTestCase {

    private var sut: MockFriendService!
    private let now = Date()

    override func setUp() {
        super.setUp()
        sut = MockFriendService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Call Tracking

    func test_sendRequest_tracksCalls() async throws {
        try await sut.sendRequest(to: "bob", from: "alice")
        XCTAssertEqual(sut.sendRequestCalls.count, 1)
        XCTAssertEqual(sut.sendRequestCalls[0].receiverID, "bob")
        XCTAssertEqual(sut.sendRequestCalls[0].senderID, "alice")
    }

    func test_acceptRequest_tracksCalls() async throws {
        try await sut.acceptRequest("req-1", by: "bob")
        XCTAssertEqual(sut.acceptRequestCalls.count, 1)
        XCTAssertEqual(sut.acceptRequestCalls[0].requestID, "req-1")
        XCTAssertEqual(sut.acceptRequestCalls[0].userID, "bob")
    }

    func test_declineRequest_tracksCalls() async throws {
        try await sut.declineRequest("req-2", by: "bob")
        XCTAssertEqual(sut.declineRequestCalls.count, 1)
    }

    func test_cancelRequest_tracksCalls() async throws {
        try await sut.cancelRequest("req-3", by: "alice")
        XCTAssertEqual(sut.cancelRequestCalls.count, 1)
    }

    func test_removeFriend_tracksCalls() async throws {
        try await sut.removeFriend("f-1")
        XCTAssertEqual(sut.removeFriendCalls, ["f-1"])
    }

    func test_refresh_tracksCalls() async throws {
        try await sut.refresh(for: "user-1")
        XCTAssertEqual(sut.refreshCalls, ["user-1"])
    }

    // MARK: - Stub Errors

    func test_sendRequest_throwsStubbedError() async {
        sut.sendRequestError = FriendServiceError.cannotFriendSelf
        do {
            try await sut.sendRequest(to: "me", from: "me")
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(error as? FriendServiceError, .cannotFriendSelf)
        }
    }

    func test_acceptRequest_throwsStubbedError() async {
        sut.acceptRequestError = FriendServiceError.requestNotFound
        do {
            try await sut.acceptRequest("nope", by: "user")
            XCTFail("Should have thrown")
        } catch {
            XCTAssertEqual(error as? FriendServiceError, .requestNotFound)
        }
    }

    // MARK: - Test Helpers

    func test_simulateIncomingRequest() {
        let request = FriendRequest(
            id: "r1", senderID: "bob", receiverID: "alice",
            status: .pending, createdAt: now, modifiedAt: now
        )
        sut.simulateIncomingRequest(request)
        XCTAssertEqual(sut.incomingRequests.count, 1)
        XCTAssertEqual(sut.incomingRequests[0].id, "r1")
    }

    func test_simulateFriendship() {
        let friendship = Friendship(id: "f1", userA: "alice", userB: "bob", createdAt: now)
        sut.simulateFriendship(friendship)
        XCTAssertTrue(sut.isFriend(with: "alice"))
        XCTAssertTrue(sut.isFriend(with: "bob"))
        XCTAssertFalse(sut.isFriend(with: "charlie"))
    }

    func test_pendingRequest_findsMatch() {
        let request = FriendRequest(
            id: "r1", senderID: "alice", receiverID: "bob",
            status: .pending, createdAt: now, modifiedAt: now
        )
        sut.simulateOutgoingRequest(request)
        XCTAssertNotNil(sut.pendingRequest(with: "bob"))
        XCTAssertNil(sut.pendingRequest(with: "charlie"))
    }

    func test_reset_clearsEverything() async throws {
        sut.simulateIncomingRequest(FriendRequest(
            id: "r1", senderID: "a", receiverID: "b",
            status: .pending, createdAt: now, modifiedAt: now
        ))
        try await sut.sendRequest(to: "x", from: "y")
        sut.sendRequestError = FriendServiceError.notSignedIn

        sut.reset()

        XCTAssertTrue(sut.incomingRequests.isEmpty)
        XCTAssertTrue(sut.sendRequestCalls.isEmpty)
        XCTAssertNil(sut.sendRequestError)
    }
}
