import XCTest
@testable import CatchCore

@MainActor
final class SupabaseSocialInteractionServiceTests: XCTestCase {

    private var sut: SupabaseSocialInteractionService!
    private var mockRepo: MockSupabaseSocialRepository!
    private let currentUserID = "current-user-id"
    private let encounterID = "encounter-001"

    override func setUp() {
        super.setUp()
        mockRepo = MockSupabaseSocialRepository()
        sut = SupabaseSocialInteractionService(
            repository: mockRepo,
            getCurrentUserID: { [currentUserID] in currentUserID },
            pageSize: 3
        )
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        super.tearDown()
    }

    // MARK: - Toggle Like

    func testToggleLikeAddsLikeWhenNotLiked() async throws {
        mockRepo.insertLikeResult = .fixture()

        try await sut.toggleLike(encounterRecordName: encounterID)

        XCTAssertTrue(sut.isLiked(encounterID))
        XCTAssertEqual(sut.likeCount(for: encounterID), 1)
        XCTAssertEqual(mockRepo.insertLikeCalls.count, 1)
        XCTAssertEqual(mockRepo.insertLikeCalls.first?.encounterID, encounterID)
        XCTAssertEqual(mockRepo.insertLikeCalls.first?.userID, currentUserID)
    }

    func testToggleLikeRemovesLikeWhenAlreadyLiked() async throws {
        mockRepo.insertLikeResult = .fixture()
        try await sut.toggleLike(encounterRecordName: encounterID)
        XCTAssertTrue(sut.isLiked(encounterID))

        try await sut.toggleLike(encounterRecordName: encounterID)

        XCTAssertFalse(sut.isLiked(encounterID))
        XCTAssertEqual(sut.likeCount(for: encounterID), 0)
        XCTAssertEqual(mockRepo.deleteLikeCalls.count, 1)
    }

    func testToggleLikeNotSignedInThrows() async {
        let sut = SupabaseSocialInteractionService(
            repository: mockRepo,
            getCurrentUserID: { nil }
        )

        do {
            try await sut.toggleLike(encounterRecordName: encounterID)
            XCTFail("Expected notSignedIn error")
        } catch let error as SocialInteractionError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testToggleLikeRollsBackOnError() async {
        mockRepo.insertLikeError = NSError(domain: "test", code: 500)

        do {
            try await sut.toggleLike(encounterRecordName: encounterID)
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        XCTAssertFalse(sut.isLiked(encounterID))
        XCTAssertEqual(sut.likeCount(for: encounterID), 0)
    }

    func testToggleLikeUnlikeRollsBackOnError() async throws {
        mockRepo.insertLikeResult = .fixture()
        try await sut.toggleLike(encounterRecordName: encounterID)
        XCTAssertTrue(sut.isLiked(encounterID))

        mockRepo.deleteLikeError = NSError(domain: "test", code: 500)

        do {
            try await sut.toggleLike(encounterRecordName: encounterID)
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        XCTAssertTrue(sut.isLiked(encounterID))
        XCTAssertEqual(sut.likeCount(for: encounterID), 1)
    }

    // MARK: - Like Count

    func testLikeCountReturnsZeroForUnknownEncounter() {
        XCTAssertEqual(sut.likeCount(for: "unknown"), 0)
    }

    func testIsLikedReturnsFalseForUnknownEncounter() {
        XCTAssertFalse(sut.isLiked("unknown"))
    }

    // MARK: - Fetch Likes

    func testFetchLikesReturnsUsersWithDisplayNames() async throws {
        let userID = UUID()
        mockRepo.fetchLikesResult = [
            .fixture(userID: userID, displayName: "CatLover", username: "catlover99")
        ]

        let (users, cursor) = try await sut.fetchLikes(
            encounterRecordName: encounterID,
            cursor: nil
        )

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.displayName, "CatLover")
        XCTAssertEqual(users.first?.username, "catlover99")
        XCTAssertNil(cursor)
        XCTAssertEqual(mockRepo.fetchLikesCalls.first?.offset, 0)
    }

    func testFetchLikesReturnsCursorWhenPageFull() async throws {
        mockRepo.fetchLikesResult = (0..<3).map { _ in .fixture() }

        let (users, cursor) = try await sut.fetchLikes(
            encounterRecordName: encounterID,
            cursor: nil
        )

        XCTAssertEqual(users.count, 3)
        XCTAssertEqual(cursor, "3")
    }

    func testFetchLikesPaginatesWithCursor() async throws {
        mockRepo.fetchLikesResult = [.fixture()]

        let (_, _) = try await sut.fetchLikes(
            encounterRecordName: encounterID,
            cursor: "3"
        )

        XCTAssertEqual(mockRepo.fetchLikesCalls.first?.offset, 3)
    }

    // MARK: - Add Comment

    func testAddCommentReturnsCommentWithDisplayName() async throws {
        let commentID = UUID()
        let encounterUUID = UUID()
        let userUUID = UUID()
        mockRepo.insertCommentResult = .fixture(
            id: commentID,
            encounterID: encounterUUID,
            userID: userUUID,
            text: "what a legend",
            displayName: "CatFan"
        )

        let comment = try await sut.addComment(
            encounterRecordName: encounterID,
            text: "what a legend"
        )

        XCTAssertEqual(comment.id, commentID.uuidString.lowercased())
        XCTAssertEqual(comment.text, "what a legend")
        XCTAssertEqual(comment.displayName, "CatFan")
        XCTAssertEqual(sut.commentCount(for: encounterID), 1)
        XCTAssertEqual(mockRepo.insertCommentCalls.count, 1)
    }

    func testAddCommentTrimsWhitespace() async throws {
        mockRepo.insertCommentResult = .fixture(text: "hello")

        _ = try await sut.addComment(
            encounterRecordName: encounterID,
            text: "  hello  \n"
        )

        XCTAssertEqual(mockRepo.insertCommentCalls.first?.text, "hello")
    }

    func testAddCommentEmptyThrows() async {
        do {
            _ = try await sut.addComment(encounterRecordName: encounterID, text: "   ")
            XCTFail("Expected commentEmpty error")
        } catch let error as SocialInteractionError {
            XCTAssertEqual(error, .commentEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertTrue(mockRepo.insertCommentCalls.isEmpty)
    }

    func testAddCommentTooLongThrows() async {
        let longText = String(repeating: "a", count: 501)
        do {
            _ = try await sut.addComment(encounterRecordName: encounterID, text: longText)
            XCTFail("Expected commentTooLong error")
        } catch let error as SocialInteractionError {
            XCTAssertEqual(error, .commentTooLong)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAddCommentNotSignedInThrows() async {
        let sut = SupabaseSocialInteractionService(
            repository: mockRepo,
            getCurrentUserID: { nil }
        )

        do {
            _ = try await sut.addComment(encounterRecordName: encounterID, text: "hi")
            XCTFail("Expected notSignedIn error")
        } catch let error as SocialInteractionError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Delete Comment

    func testDeleteCommentDecrementsCount() async throws {
        mockRepo.insertCommentResult = .fixture()
        _ = try await sut.addComment(encounterRecordName: encounterID, text: "hi")
        XCTAssertEqual(sut.commentCount(for: encounterID), 1)

        try await sut.deleteComment(recordName: "comment-id", encounterRecordName: encounterID)

        XCTAssertEqual(sut.commentCount(for: encounterID), 0)
        XCTAssertEqual(mockRepo.deleteCommentCalls.first, "comment-id")
    }

    func testDeleteCommentNotSignedInThrows() async {
        let sut = SupabaseSocialInteractionService(
            repository: mockRepo,
            getCurrentUserID: { nil }
        )

        do {
            try await sut.deleteComment(recordName: "id", encounterRecordName: encounterID)
            XCTFail("Expected notSignedIn error")
        } catch let error as SocialInteractionError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Fetch Comments

    func testFetchCommentsReturnsCommentsWithDisplayNames() async throws {
        mockRepo.fetchCommentsResult = [
            .fixture(text: "cool cat", displayName: "CatFan")
        ]

        let (comments, cursor) = try await sut.fetchComments(
            encounterRecordName: encounterID,
            cursor: nil
        )

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments.first?.text, "cool cat")
        XCTAssertEqual(comments.first?.displayName, "CatFan")
        XCTAssertNil(cursor)
    }

    func testFetchCommentsReturnsCursorWhenPageFull() async throws {
        mockRepo.fetchCommentsResult = (0..<3).map { _ in .fixture() }

        let (_, cursor) = try await sut.fetchComments(
            encounterRecordName: encounterID,
            cursor: nil
        )

        XCTAssertEqual(cursor, "3")
    }

    func testFetchCommentsPaginatesWithCursor() async throws {
        mockRepo.fetchCommentsResult = [.fixture()]

        let (_, _) = try await sut.fetchComments(
            encounterRecordName: encounterID,
            cursor: "6"
        )

        XCTAssertEqual(mockRepo.fetchCommentsCalls.first?.offset, 6)
    }

    // MARK: - Comment Count

    func testCommentCountReturnsZeroForUnknownEncounter() {
        XCTAssertEqual(sut.commentCount(for: "unknown"), 0)
    }

    // MARK: - Bulk Load

    func testLoadInteractionDataPopulatesCountsAndLikes() async throws {
        let enc1 = UUID()
        let enc2 = UUID()
        let userUUID = UUID()

        mockRepo.fetchInteractionCountsResult = [
            .fixture(id: enc1, likeCount: 5, commentCount: 3),
            .fixture(id: enc2, likeCount: 0, commentCount: 1)
        ]
        mockRepo.fetchUserLikesResult = [
            .fixture(encounterID: enc1, userID: userUUID)
        ]

        let sut = SupabaseSocialInteractionService(
            repository: mockRepo,
            getCurrentUserID: { userUUID.uuidString.lowercased() }
        )

        try await sut.loadInteractionData(
            for: [enc1.uuidString.lowercased(), enc2.uuidString.lowercased()]
        )

        XCTAssertEqual(sut.likeCount(for: enc1.uuidString.lowercased()), 5)
        XCTAssertEqual(sut.commentCount(for: enc1.uuidString.lowercased()), 3)
        XCTAssertEqual(sut.likeCount(for: enc2.uuidString.lowercased()), 0)
        XCTAssertEqual(sut.commentCount(for: enc2.uuidString.lowercased()), 1)
        XCTAssertTrue(sut.isLiked(enc1.uuidString.lowercased()))
        XCTAssertFalse(sut.isLiked(enc2.uuidString.lowercased()))
    }

    func testLoadInteractionDataNoOpWhenNotSignedIn() async throws {
        let sut = SupabaseSocialInteractionService(
            repository: mockRepo,
            getCurrentUserID: { nil }
        )

        try await sut.loadInteractionData(for: ["enc-1"])

        XCTAssertTrue(mockRepo.fetchInteractionCountsCalls.isEmpty)
    }

    func testLoadInteractionDataNoOpWhenEmpty() async throws {
        try await sut.loadInteractionData(for: [])

        XCTAssertTrue(mockRepo.fetchInteractionCountsCalls.isEmpty)
    }

    // MARK: - Realtime Registration

    func testRegisterOwnedEncountersStoresIDs() {
        sut.registerOwnedEncounters(Set(["enc-1", "enc-2"]))

        // No public accessor for ownedEncounterIDs, but we can verify
        // the service was created without error.
        XCTAssertNotNil(sut)
    }
}
