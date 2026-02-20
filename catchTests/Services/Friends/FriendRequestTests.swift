import XCTest

@MainActor
final class FriendRequestTests: XCTestCase {

    private let now = Date()

    private func makeRequest(
        status: FriendRequestStatus = .pending,
        senderID: String = "sender-1",
        receiverID: String = "receiver-1"
    ) -> FriendRequest {
        FriendRequest(
            id: "req-1",
            senderID: senderID,
            receiverID: receiverID,
            status: status,
            createdAt: now,
            modifiedAt: now
        )
    }

    // MARK: - Identifiable

    func test_identifiable() {
        let request = makeRequest()
        XCTAssertEqual(request.id, "req-1")
    }

    // MARK: - Status Booleans

    func test_isPending() {
        XCTAssertTrue(makeRequest(status: .pending).isPending)
        XCTAssertFalse(makeRequest(status: .accepted).isPending)
    }

    func test_isAccepted() {
        XCTAssertTrue(makeRequest(status: .accepted).isAccepted)
        XCTAssertFalse(makeRequest(status: .pending).isAccepted)
    }

    func test_isDeclined() {
        XCTAssertTrue(makeRequest(status: .declined).isDeclined)
        XCTAssertFalse(makeRequest(status: .pending).isDeclined)
    }

    func test_isCancelled() {
        XCTAssertTrue(makeRequest(status: .cancelled).isCancelled)
        XCTAssertFalse(makeRequest(status: .pending).isCancelled)
    }

    // MARK: - Sender/Receiver

    func test_isSender() {
        let request = makeRequest(senderID: "alice", receiverID: "bob")
        XCTAssertTrue(request.isSender("alice"))
        XCTAssertFalse(request.isSender("bob"))
    }

    func test_isReceiver() {
        let request = makeRequest(senderID: "alice", receiverID: "bob")
        XCTAssertTrue(request.isReceiver("bob"))
        XCTAssertFalse(request.isReceiver("alice"))
    }

    func test_otherUserID() {
        let request = makeRequest(senderID: "alice", receiverID: "bob")
        XCTAssertEqual(request.otherUserID(for: "alice"), "bob")
        XCTAssertEqual(request.otherUserID(for: "bob"), "alice")
    }

    // MARK: - Equatable

    func test_equatable() {
        let a = makeRequest()
        let b = makeRequest()
        XCTAssertEqual(a, b)

        let c = FriendRequest(
            id: "different",
            senderID: "sender-1",
            receiverID: "receiver-1",
            status: .pending,
            createdAt: now,
            modifiedAt: now
        )
        XCTAssertNotEqual(a, c)
    }
}
