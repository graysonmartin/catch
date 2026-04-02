import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class MockSocialInteractionService: SocialInteractionService {
    var likeCounts: [String: Int] = [:]
    var commentCounts: [String: Int] = [:]
    var likedEncounters: Set<String> = []

    private(set) var toggleLikeCalls: [String] = []
    private(set) var addCommentCalls: [(encounterRecordName: String, text: String)] = []
    private(set) var deleteCommentCalls: [(recordName: String, encounterRecordName: String)] = []
    private(set) var fetchCommentsCalls: [(encounterRecordName: String, cursor: String?)] = []
    private(set) var fetchLikesCalls: [(encounterRecordName: String, cursor: String?)] = []
    private(set) var loadInteractionDataCalls: [[String]] = []

    var toggleLikeError: SocialInteractionError?
    var addCommentError: SocialInteractionError?
    var deleteCommentError: SocialInteractionError?
    var fetchCommentsResult: ([EncounterComment], String?) = ([], nil)
    var fetchLikesResult: ([LikedByUser], String?) = ([], nil)

    func toggleLike(encounterRecordName: String) async throws {
        toggleLikeCalls.append(encounterRecordName)
        if let error = toggleLikeError { throw error }

        if likedEncounters.contains(encounterRecordName) {
            likedEncounters.remove(encounterRecordName)
            likeCounts[encounterRecordName, default: 1] -= 1
        } else {
            likedEncounters.insert(encounterRecordName)
            likeCounts[encounterRecordName, default: 0] += 1
        }
    }

    func isLiked(_ encounterRecordName: String) -> Bool {
        likedEncounters.contains(encounterRecordName)
    }

    func likeCount(for encounterRecordName: String) -> Int {
        likeCounts[encounterRecordName, default: 0]
    }

    func addComment(encounterRecordName: String, text: String) async throws -> EncounterComment {
        addCommentCalls.append((encounterRecordName, text))
        if let error = addCommentError { throw error }

        let comment = EncounterComment(
            id: "mock-comment-\(UUID().uuidString)",
            encounterRecordName: encounterRecordName,
            userID: "mock-user",
            text: text,
            createdAt: Date()
        )
        commentCounts[encounterRecordName, default: 0] += 1
        return comment
    }

    func deleteComment(recordName: String, encounterRecordName: String) async throws {
        deleteCommentCalls.append((recordName, encounterRecordName))
        if let error = deleteCommentError { throw error }
        commentCounts[encounterRecordName, default: 1] -= 1
    }

    func fetchComments(encounterRecordName: String, cursor: String?) async throws -> ([EncounterComment], String?) {
        fetchCommentsCalls.append((encounterRecordName, cursor))
        return fetchCommentsResult
    }

    func fetchLikes(encounterRecordName: String, cursor: String?) async throws -> ([LikedByUser], String?) {
        fetchLikesCalls.append((encounterRecordName, cursor))
        return fetchLikesResult
    }

    func commentCount(for encounterRecordName: String) -> Int {
        commentCounts[encounterRecordName, default: 0]
    }

    func loadInteractionData(for encounterRecordNames: [String]) async throws {
        loadInteractionDataCalls.append(encounterRecordNames)
    }

    func resetState() async {
        reset()
    }

    // MARK: - Test Helpers

    func reset() {
        likeCounts = [:]
        commentCounts = [:]
        likedEncounters = []
        toggleLikeCalls = []
        addCommentCalls = []
        deleteCommentCalls = []
        fetchCommentsCalls = []
        fetchLikesCalls = []
        loadInteractionDataCalls = []
        toggleLikeError = nil
        addCommentError = nil
        deleteCommentError = nil
        fetchCommentsResult = ([], nil)
        fetchLikesResult = ([], nil)
    }
}
