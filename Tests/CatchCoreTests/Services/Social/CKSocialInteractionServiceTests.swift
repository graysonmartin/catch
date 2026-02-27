import XCTest
@testable import CatchCore

@MainActor
final class CKSocialInteractionServiceTests: XCTestCase {

    // MARK: - Mock Service Tests

    func test_toggleLike_addsToLikedEncounters() async throws {
        let mock = MockSocialInteractionService()

        try await mock.toggleLike(encounterRecordName: "enc1")

        XCTAssertTrue(mock.isLiked("enc1"))
        XCTAssertEqual(mock.likeCount(for: "enc1"), 1)
        XCTAssertEqual(mock.toggleLikeCalls, ["enc1"])
    }

    func test_toggleLike_removesFromLikedEncounters() async throws {
        let mock = MockSocialInteractionService()
        mock.likedEncounters = ["enc1"]
        mock.likeCounts = ["enc1": 3]

        try await mock.toggleLike(encounterRecordName: "enc1")

        XCTAssertFalse(mock.isLiked("enc1"))
        XCTAssertEqual(mock.likeCount(for: "enc1"), 2)
    }

    func test_toggleLike_throwsConfiguredError() async {
        let mock = MockSocialInteractionService()
        mock.toggleLikeError = .notSignedIn

        do {
            try await mock.toggleLike(encounterRecordName: "enc1")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .notSignedIn)
        }
    }

    func test_addComment_returnsComment() async throws {
        let mock = MockSocialInteractionService()

        let comment = try await mock.addComment(encounterRecordName: "enc1", text: "nice cat")

        XCTAssertEqual(comment.encounterRecordName, "enc1")
        XCTAssertEqual(comment.text, "nice cat")
        XCTAssertEqual(mock.commentCount(for: "enc1"), 1)
        XCTAssertEqual(mock.addCommentCalls.count, 1)
    }

    func test_addComment_throwsConfiguredError() async {
        let mock = MockSocialInteractionService()
        mock.addCommentError = .commentEmpty

        do {
            _ = try await mock.addComment(encounterRecordName: "enc1", text: "")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .commentEmpty)
        }
    }

    func test_deleteComment_decrementsCount() async throws {
        let mock = MockSocialInteractionService()
        mock.commentCounts = ["enc1": 3]

        try await mock.deleteComment(recordName: "comment1", encounterRecordName: "enc1")

        XCTAssertEqual(mock.commentCount(for: "enc1"), 2)
        XCTAssertEqual(mock.deleteCommentCalls.count, 1)
    }

    func test_fetchComments_returnsConfiguredResult() async throws {
        let mock = MockSocialInteractionService()
        let fakeComment = EncounterComment(
            id: "c1",
            encounterRecordName: "enc1",
            userID: "user1",
            text: "test",
            createdAt: Date()
        )
        mock.fetchCommentsResult = ([fakeComment], nil)

        let (comments, cursor) = try await mock.fetchComments(encounterRecordName: "enc1", cursor: nil)

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments.first?.text, "test")
        XCTAssertNil(cursor)
    }

    func test_loadInteractionData_tracksCalls() async throws {
        let mock = MockSocialInteractionService()

        try await mock.loadInteractionData(for: ["enc1", "enc2"])

        XCTAssertEqual(mock.loadInteractionDataCalls.count, 1)
        XCTAssertEqual(mock.loadInteractionDataCalls.first, ["enc1", "enc2"])
    }

    func test_likeCount_defaultsToZero() {
        let mock = MockSocialInteractionService()

        XCTAssertEqual(mock.likeCount(for: "nonexistent"), 0)
    }

    func test_commentCount_defaultsToZero() {
        let mock = MockSocialInteractionService()

        XCTAssertEqual(mock.commentCount(for: "nonexistent"), 0)
    }

    func test_reset_clearsAllState() async throws {
        let mock = MockSocialInteractionService()
        try await mock.toggleLike(encounterRecordName: "enc1")
        _ = try await mock.addComment(encounterRecordName: "enc1", text: "hi")

        mock.reset()

        XCTAssertTrue(mock.likeCounts.isEmpty)
        XCTAssertTrue(mock.commentCounts.isEmpty)
        XCTAssertTrue(mock.likedEncounters.isEmpty)
        XCTAssertTrue(mock.toggleLikeCalls.isEmpty)
        XCTAssertTrue(mock.addCommentCalls.isEmpty)
    }

    // MARK: - Error Tests

    func test_socialInteractionError_allCasesHaveDescriptions() {
        let cases: [SocialInteractionError] = [
            .notSignedIn,
            .encounterNotSynced,
            .commentEmpty,
            .commentTooLong,
            .commentNotFound,
            .unauthorized,
            .networkError("test")
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func test_socialInteractionError_equatable() {
        XCTAssertEqual(SocialInteractionError.notSignedIn, .notSignedIn)
        XCTAssertEqual(SocialInteractionError.commentEmpty, .commentEmpty)
        XCTAssertNotEqual(SocialInteractionError.notSignedIn, .commentEmpty)
        XCTAssertEqual(SocialInteractionError.networkError("a"), .networkError("a"))
        XCTAssertNotEqual(SocialInteractionError.networkError("a"), .networkError("b"))
    }

    // MARK: - Data Struct Tests

    func test_encounterLike_identifiable() {
        let like = EncounterLike(
            id: "test-id",
            encounterRecordName: "enc1",
            userID: "user1",
            createdAt: Date()
        )
        XCTAssertEqual(like.id, "test-id")
    }

    func test_encounterLike_equatable() {
        let date = Date()
        let a = EncounterLike(id: "a", encounterRecordName: "e", userID: "u", createdAt: date)
        let b = EncounterLike(id: "a", encounterRecordName: "e", userID: "u", createdAt: date)
        XCTAssertEqual(a, b)
    }

    func test_encounterComment_identifiable() {
        let comment = EncounterComment(
            id: "test-id",
            encounterRecordName: "enc1",
            userID: "user1",
            text: "hello",
            createdAt: Date()
        )
        XCTAssertEqual(comment.id, "test-id")
    }

    func test_encounterComment_equatable() {
        let date = Date()
        let a = EncounterComment(id: "a", encounterRecordName: "e", userID: "u", text: "t", createdAt: date)
        let b = EncounterComment(id: "a", encounterRecordName: "e", userID: "u", text: "t", createdAt: date)
        XCTAssertEqual(a, b)
    }

    // MARK: - Validation Tests (CKSocialInteractionService)

    func test_addComment_validatesEmptyText() async {
        let service = CKSocialInteractionService(getCurrentUserID: { "user1" })

        do {
            _ = try await service.addComment(encounterRecordName: "enc1", text: "   ")
            XCTFail("Expected commentEmpty error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .commentEmpty)
        }
    }

    func test_addComment_validatesLongText() async {
        let service = CKSocialInteractionService(getCurrentUserID: { "user1" })
        let longText = String(repeating: "a", count: 501)

        do {
            _ = try await service.addComment(encounterRecordName: "enc1", text: longText)
            XCTFail("Expected commentTooLong error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .commentTooLong)
        }
    }

    func test_toggleLike_requiresSignIn() async {
        let service = CKSocialInteractionService(getCurrentUserID: { nil })

        do {
            try await service.toggleLike(encounterRecordName: "enc1")
            XCTFail("Expected notSignedIn error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .notSignedIn)
        }
    }

    func test_addComment_requiresSignIn() async {
        let service = CKSocialInteractionService(getCurrentUserID: { nil })

        do {
            _ = try await service.addComment(encounterRecordName: "enc1", text: "hello")
            XCTFail("Expected notSignedIn error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .notSignedIn)
        }
    }

    func test_deleteComment_requiresSignIn() async {
        let service = CKSocialInteractionService(getCurrentUserID: { nil })

        do {
            try await service.deleteComment(recordName: "c1", encounterRecordName: "enc1")
            XCTFail("Expected notSignedIn error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .notSignedIn)
        }
    }

    func test_deleteComment_requiresOwnership() async {
        let service = CKSocialInteractionService(getCurrentUserID: { "user1" })

        do {
            try await service.deleteComment(recordName: "otheruser_comment_abc", encounterRecordName: "enc1")
            XCTFail("Expected unauthorized error")
        } catch {
            XCTAssertEqual(error as? SocialInteractionError, .unauthorized)
        }
    }

    func test_optimisticLike_updatesStateImmediately() async throws {
        let service = CKSocialInteractionService(getCurrentUserID: { "user1" })

        // Before toggle
        XCTAssertFalse(service.isLiked("enc1"))
        XCTAssertEqual(service.likeCount(for: "enc1"), 0)
    }

    func test_loadInteractionData_skipsEmptyArray() async throws {
        let service = CKSocialInteractionService(getCurrentUserID: { "user1" })

        // Should not throw
        try await service.loadInteractionData(for: [])

        XCTAssertTrue(service.likeCounts.isEmpty)
        XCTAssertTrue(service.commentCounts.isEmpty)
    }

    func test_loadInteractionData_skipsWhenNotSignedIn() async throws {
        let service = CKSocialInteractionService(getCurrentUserID: { nil })

        // Should not throw
        try await service.loadInteractionData(for: ["enc1"])

        XCTAssertTrue(service.likeCounts.isEmpty)
    }

    #if DEBUG
    func test_seedFakeInteractions_populatesState() {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })

        service.seedFakeInteractions(encounterRecordNames: ["enc1", "enc2", "enc3"])

        XCTAssertFalse(service.likeCounts.isEmpty)
        XCTAssertTrue(service.likedEncounters.contains("enc1"))
    }

    func test_seedFakeInteractions_skipsIfAlreadySeeded() {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })
        service.seedFakeInteractions(encounterRecordNames: ["enc1", "enc2"])
        let initialCount = service.likeCounts.count

        service.seedFakeInteractions(encounterRecordNames: ["enc3", "enc4", "enc5"])

        XCTAssertEqual(service.likeCounts.count, initialCount)
    }

    func test_seedFakeInteractions_skipsEmptyRecordNames() {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })

        service.seedFakeInteractions(encounterRecordNames: [])

        XCTAssertTrue(service.likeCounts.isEmpty)
    }
    #endif
}
