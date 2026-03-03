import XCTest
@testable import CatchCore

final class EncounterCommentTests: XCTestCase {

    // MARK: - Pending Factory

    func test_pending_setsIsPendingTrue() {
        let comment = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            text: "nice cat"
        )

        XCTAssertTrue(comment.isPending)
        XCTAssertEqual(comment.encounterRecordName, "enc1")
        XCTAssertEqual(comment.userID, "user1")
        XCTAssertEqual(comment.text, "nice cat")
    }

    func test_pending_generatesUniqueIDs() {
        let a = EncounterComment.pending(encounterRecordName: "enc1", userID: "u", text: "a")
        let b = EncounterComment.pending(encounterRecordName: "enc1", userID: "u", text: "b")

        XCTAssertNotEqual(a.id, b.id)
    }

    func test_pending_idHasPendingPrefix() {
        let comment = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            text: "test"
        )

        XCTAssertTrue(comment.id.hasPrefix("pending_"))
    }

    // MARK: - Confirmed

    func test_confirmed_setsIsPendingFalse() {
        let pending = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            text: "hello"
        )
        XCTAssertTrue(pending.isPending)

        let confirmed = pending.confirmed(withID: "server-id-123")

        XCTAssertFalse(confirmed.isPending)
        XCTAssertEqual(confirmed.id, "server-id-123")
    }

    func test_confirmed_preservesContent() {
        let pending = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            text: "hello world"
        )

        let confirmed = pending.confirmed(withID: "server-id")

        XCTAssertEqual(confirmed.encounterRecordName, pending.encounterRecordName)
        XCTAssertEqual(confirmed.userID, pending.userID)
        XCTAssertEqual(confirmed.text, pending.text)
        XCTAssertEqual(confirmed.createdAt, pending.createdAt)
    }

    // MARK: - Default isPending

    func test_defaultInit_isPendingIsFalse() {
        let comment = EncounterComment(
            id: "c1",
            encounterRecordName: "enc1",
            userID: "user1",
            text: "test",
            createdAt: Date()
        )

        XCTAssertFalse(comment.isPending)
    }

    // MARK: - Equatable

    func test_pendingAndConfirmed_areNotEqual() {
        let date = Date()
        let pending = EncounterComment(
            id: "c1",
            encounterRecordName: "enc1",
            userID: "user1",
            text: "test",
            createdAt: date,
            isPending: true
        )
        let confirmed = EncounterComment(
            id: "c1",
            encounterRecordName: "enc1",
            userID: "user1",
            text: "test",
            createdAt: date,
            isPending: false
        )

        XCTAssertNotEqual(pending, confirmed)
    }
}
