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

    // MARK: - resolveLikeUsers Deduplication

    func test_resolveLikeUsers_deduplicatesUserIDsBeforeFetching() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )

        mockCloudKit.fetchResultsByUserID = [
            "user-a": CloudUserProfile(
                recordName: "rec-a", appleUserID: "user-a",
                displayName: "alice", bio: "", isPrivate: false
            ),
            "user-b": CloudUserProfile(
                recordName: "rec-b", appleUserID: "user-b",
                displayName: "bob", bio: "", isPrivate: false
            )
        ]

        let now = Date()
        let likes = [
            EncounterLike(id: "like-1", encounterRecordName: "enc1", userID: "user-a", createdAt: now),
            EncounterLike(id: "like-2", encounterRecordName: "enc1", userID: "user-a", createdAt: now.addingTimeInterval(-60)),
            EncounterLike(id: "like-3", encounterRecordName: "enc1", userID: "user-b", createdAt: now.addingTimeInterval(-120)),
            EncounterLike(id: "like-4", encounterRecordName: "enc1", userID: "user-a", createdAt: now.addingTimeInterval(-180)),
        ]

        let users = await service.resolveLikeUsers(likes)

        // Should fetch only 2 unique profiles, not 4
        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs.sorted(), ["user-a", "user-b"])

        // Should return 4 LikedByUser entries (one per like)
        XCTAssertEqual(users.count, 4)

        // All user-a entries should have the resolved display name
        let aliceUsers = users.filter { $0.userID == "user-a" }
        XCTAssertEqual(aliceUsers.count, 3)
        for user in aliceUsers {
            XCTAssertEqual(user.displayName, "alice")
        }

        // user-b entry should have the resolved display name
        let bobUsers = users.filter { $0.userID == "user-b" }
        XCTAssertEqual(bobUsers.count, 1)
        XCTAssertEqual(bobUsers.first?.displayName, "bob")
    }

    func test_resolveLikeUsers_fallsBackToTruncatedIDWhenProfileNotFound() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )
        // No profiles configured — fetchResult is nil by default

        let likes = [
            EncounterLike(id: "like-1", encounterRecordName: "enc1", userID: "long-user-id-12345", createdAt: Date()),
        ]

        let users = await service.resolveLikeUsers(likes)

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.displayName, "long-use")
        XCTAssertNil(users.first?.username)
    }

    func test_resolveLikeUsers_returnsEmptyForEmptyInput() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )

        let users = await service.resolveLikeUsers([])

        XCTAssertTrue(users.isEmpty)
        XCTAssertTrue(mockCloudKit.fetchedAppleUserIDs.isEmpty)
    }

    func test_resolveLikeUsers_preservesSortByDateDescending() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )

        mockCloudKit.fetchResultsByUserID = [
            "user-a": CloudUserProfile(
                recordName: "rec-a", appleUserID: "user-a",
                displayName: "alice", bio: "", isPrivate: false
            )
        ]

        let now = Date()
        let likes = [
            EncounterLike(id: "like-old", encounterRecordName: "enc1", userID: "user-a", createdAt: now.addingTimeInterval(-1000)),
            EncounterLike(id: "like-new", encounterRecordName: "enc1", userID: "user-a", createdAt: now),
            EncounterLike(id: "like-mid", encounterRecordName: "enc1", userID: "user-a", createdAt: now.addingTimeInterval(-500)),
        ]

        let users = await service.resolveLikeUsers(likes)

        // Should be sorted newest first
        XCTAssertEqual(users.map(\.id), ["like-new", "like-mid", "like-old"])
    }

    // MARK: - Current User Profile Caching

    func test_resolveCurrentUserProfile_cachesAfterFirstFetch() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )

        mockCloudKit.fetchResult = CloudUserProfile(
            recordName: "rec-1", appleUserID: "user1",
            displayName: "me", bio: "", isPrivate: false
        )

        // First call — should fetch
        let profile1 = await service.resolveCurrentUserProfile(userID: "user1")
        XCTAssertEqual(profile1?.displayName, "me")
        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs.count, 1)

        // Second call — should use cache
        let profile2 = await service.resolveCurrentUserProfile(userID: "user1")
        XCTAssertEqual(profile2?.displayName, "me")
        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs.count, 1, "should not fetch again")
    }

    func test_resolveCurrentUserProfile_refetchesForDifferentUser() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )

        mockCloudKit.fetchResultsByUserID = [
            "user1": CloudUserProfile(
                recordName: "rec-1", appleUserID: "user1",
                displayName: "me", bio: "", isPrivate: false
            ),
            "user2": CloudUserProfile(
                recordName: "rec-2", appleUserID: "user2",
                displayName: "other", bio: "", isPrivate: false
            )
        ]

        _ = await service.resolveCurrentUserProfile(userID: "user1")
        let profile2 = await service.resolveCurrentUserProfile(userID: "user2")

        XCTAssertEqual(profile2?.displayName, "other")
        XCTAssertEqual(mockCloudKit.fetchedAppleUserIDs.count, 2, "should fetch for different user ID")
    }

    func test_resolveCurrentUserProfile_returnsNilWhenNoCloudKitProfile() async {
        let mockCloudKit = MockCloudKitService()
        let service = CKSocialInteractionService(
            getCurrentUserID: { "user1" },
            cloudKitService: mockCloudKit
        )
        // fetchResult is nil by default

        let profile = await service.resolveCurrentUserProfile(userID: "user1")

        XCTAssertNil(profile)
    }

    #if DEBUG
    func test_seedFakeInteractions_populatesState() {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })

        service.seedFakeInteractions(encounterRecordNames: ["enc1", "enc2", "enc3"])

        XCTAssertFalse(service.likeCounts.isEmpty)
        XCTAssertTrue(service.likedEncounters.contains("enc1"))
    }

    func test_seedFakeInteractions_populatesCommentCache() async throws {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })

        service.seedFakeInteractions(encounterRecordNames: ["enc1", "enc2", "enc3"])

        // enc1 has index 0 -> commentCount = max(0, 0) = 0
        // enc2 has index 1 -> commentCount = max(0, 1) = 1
        // enc3 has index 2 -> commentCount = max(0, 2) = 2
        let (comments1, _) = try await service.fetchComments(encounterRecordName: "enc1", cursor: nil)
        let (comments2, _) = try await service.fetchComments(encounterRecordName: "enc2", cursor: nil)
        let (comments3, _) = try await service.fetchComments(encounterRecordName: "enc3", cursor: nil)

        XCTAssertEqual(comments1.count, 0)
        XCTAssertEqual(comments2.count, 1)
        XCTAssertEqual(comments3.count, 2)
    }

    func test_seedFakeInteractions_populatesLikeCache() async throws {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })

        service.seedFakeInteractions(encounterRecordNames: ["enc1", "enc2", "enc3"])

        // enc1 has index 0 -> likeCount = (0+1)*2 = 2
        // enc2 has index 1 -> likeCount = (1+1)*2 = 4
        let (likes1, _) = try await service.fetchLikes(encounterRecordName: "enc1", cursor: nil)
        let (likes2, _) = try await service.fetchLikes(encounterRecordName: "enc2", cursor: nil)

        XCTAssertEqual(likes1.count, 2)
        XCTAssertEqual(likes2.count, 4)
    }

    func test_seedFakeInteractions_likeCacheMatchesCounts() async throws {
        let service = CKSocialInteractionService(getCurrentUserID: { "debug-user" })

        service.seedFakeInteractions(encounterRecordNames: ["enc1", "enc2", "enc3", "enc4", "enc5"])

        for (index, recordName) in ["enc1", "enc2", "enc3", "enc4", "enc5"].enumerated() {
            let expectedLikes = (index + 1) * 2
            let expectedComments = max(0, index)

            XCTAssertEqual(service.likeCount(for: recordName), expectedLikes)
            XCTAssertEqual(service.commentCount(for: recordName), expectedComments)

            let (likes, _) = try await service.fetchLikes(encounterRecordName: recordName, cursor: nil)
            XCTAssertEqual(likes.count, expectedLikes, "Like detail count mismatch for \(recordName)")

            let (comments, _) = try await service.fetchComments(encounterRecordName: recordName, cursor: nil)
            XCTAssertEqual(comments.count, expectedComments, "Comment detail count mismatch for \(recordName)")
        }
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
