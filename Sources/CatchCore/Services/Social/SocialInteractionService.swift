import Foundation

@MainActor
public protocol SocialInteractionService: Observable, Sendable {
    var likeCounts: [String: Int] { get }
    var commentCounts: [String: Int] { get }
    var likedEncounters: Set<String> { get }

    func toggleLike(encounterRecordName: String) async throws
    func isLiked(_ encounterRecordName: String) -> Bool
    func likeCount(for encounterRecordName: String) -> Int
    func fetchLikes(encounterRecordName: String, cursor: String?) async throws -> ([LikedByUser], String?)

    func addComment(encounterRecordName: String, text: String) async throws -> EncounterComment
    func deleteComment(recordName: String, encounterRecordName: String) async throws
    func fetchComments(encounterRecordName: String, cursor: String?) async throws -> ([EncounterComment], String?)
    func commentCount(for encounterRecordName: String) -> Int

    func loadInteractionData(for encounterRecordNames: [String]) async throws
    func resetState() async
}
