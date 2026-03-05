import XCTest
@testable import CatchCore

final class EncounterCommentTests: XCTestCase {

    // MARK: - Pending Factory

    func test_pending_setsIsPendingTrue() {
        let comment = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            displayName: "user one",
            text: "nice cat"
        )

        XCTAssertTrue(comment.isPending)
        XCTAssertEqual(comment.encounterRecordName, "enc1")
        XCTAssertEqual(comment.userID, "user1")
        XCTAssertEqual(comment.text, "nice cat")
    }

    func test_pending_generatesUniqueIDs() {
        let a = EncounterComment.pending(encounterRecordName: "enc1", userID: "u", displayName: nil, text: "a")
        let b = EncounterComment.pending(encounterRecordName: "enc1", userID: "u", displayName: nil, text: "b")

        XCTAssertNotEqual(a.id, b.id)
    }

    func test_pending_idHasPendingPrefix() {
        let comment = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            displayName: nil,
            text: "test"
        )

        XCTAssertTrue(comment.id.hasPrefix("pending_"))
    }

    // MARK: - Confirmed

    func test_confirmed_setsIsPendingFalse() {
        let pending = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            displayName: "user one",
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
            displayName: "user one",
            text: "hello world"
        )

        let confirmed = pending.confirmed(withID: "server-id")

        XCTAssertEqual(confirmed.encounterRecordName, pending.encounterRecordName)
        XCTAssertEqual(confirmed.userID, pending.userID)
        XCTAssertEqual(confirmed.displayName, pending.displayName)
        XCTAssertEqual(confirmed.text, pending.text)
        XCTAssertEqual(confirmed.createdAt, pending.createdAt)
    }

    // MARK: - Author Name

    func test_authorName_returnsDisplayNameWhenSet() {
        let comment = EncounterComment(
            id: "c1",
            encounterRecordName: "enc1",
            userID: "long-apple-user-id-here",
            displayName: "tuong",
            text: "nice",
            createdAt: Date()
        )

        XCTAssertEqual(comment.authorName, "tuong")
    }

    func test_authorName_fallsBackToTruncatedUserID() {
        let comment = EncounterComment(
            id: "c1",
            encounterRecordName: "enc1",
            userID: "long-apple-user-id-here",
            text: "nice",
            createdAt: Date()
        )

        XCTAssertEqual(comment.authorName, "long-app")
    }

    func test_pending_preservesDisplayName() {
        let comment = EncounterComment.pending(
            encounterRecordName: "enc1",
            userID: "user1",
            displayName: "cat person",
            text: "wow"
        )

        XCTAssertEqual(comment.displayName, "cat person")
        XCTAssertEqual(comment.authorName, "cat person")
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
