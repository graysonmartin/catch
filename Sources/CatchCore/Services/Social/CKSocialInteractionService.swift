import CloudKit
import Observation

@Observable
@MainActor
public final class CKSocialInteractionService: SocialInteractionService {
    public private(set) var likeCounts: [String: Int] = [:]
    public private(set) var commentCounts: [String: Int] = [:]
    public private(set) var likedEncounters: Set<String> = []

    private static let containerID = "iCloud.com.catch.catch"
    private let getCurrentUserID: () -> String?

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    public init(getCurrentUserID: @escaping @Sendable () -> String?) {
        self.getCurrentUserID = getCurrentUserID
    }

    // MARK: - Likes

    public func toggleLike(encounterRecordName: String) async throws {
        guard let userID = getCurrentUserID() else {
            throw SocialInteractionError.notSignedIn
        }

        let wasLiked = likedEncounters.contains(encounterRecordName)

        // Optimistic update
        if wasLiked {
            likedEncounters.remove(encounterRecordName)
            likeCounts[encounterRecordName, default: 1] -= 1
        } else {
            likedEncounters.insert(encounterRecordName)
            likeCounts[encounterRecordName, default: 0] += 1
        }

        do {
            if wasLiked {
                let recordName = "\(userID)_like_\(encounterRecordName)"
                let recordID = CKRecord.ID(recordName: recordName)
                try await database.deleteRecord(withID: recordID)
            } else {
                let like = EncounterLike(
                    id: "\(userID)_like_\(encounterRecordName)",
                    encounterRecordName: encounterRecordName,
                    userID: userID,
                    createdAt: Date()
                )
                let record = LikeRecordMapper.record(from: like)
                _ = try await database.save(record)
            }
        } catch {
            // Roll back optimistic update
            if wasLiked {
                likedEncounters.insert(encounterRecordName)
                likeCounts[encounterRecordName, default: 0] += 1
            } else {
                likedEncounters.remove(encounterRecordName)
                likeCounts[encounterRecordName, default: 1] -= 1
            }
            throw error
        }
    }

    public func isLiked(_ encounterRecordName: String) -> Bool {
        likedEncounters.contains(encounterRecordName)
    }

    public func likeCount(for encounterRecordName: String) -> Int {
        likeCounts[encounterRecordName, default: 0]
    }

    // MARK: - Comments

    public func addComment(encounterRecordName: String, text: String) async throws -> EncounterComment {
        guard let userID = getCurrentUserID() else {
            throw SocialInteractionError.notSignedIn
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SocialInteractionError.commentEmpty }
        guard trimmed.count <= 500 else { throw SocialInteractionError.commentTooLong }

        let comment = EncounterComment(
            id: "\(userID)_comment_\(UUID().uuidString)",
            encounterRecordName: encounterRecordName,
            userID: userID,
            text: trimmed,
            createdAt: Date()
        )

        let record = CommentRecordMapper.record(from: comment)
        _ = try await database.save(record)

        commentCounts[encounterRecordName, default: 0] += 1
        return comment
    }

    public func deleteComment(recordName: String, encounterRecordName: String) async throws {
        guard let userID = getCurrentUserID() else {
            throw SocialInteractionError.notSignedIn
        }

        // Verify ownership via record name prefix
        guard recordName.hasPrefix("\(userID)_comment_") else {
            throw SocialInteractionError.unauthorized
        }

        let recordID = CKRecord.ID(recordName: recordName)
        try await database.deleteRecord(withID: recordID)

        commentCounts[encounterRecordName, default: 1] -= 1
    }

    public func fetchComments(
        encounterRecordName: String,
        cursor: String?
    ) async throws -> ([EncounterComment], String?) {
        let predicate = NSPredicate(format: "encounterRecordName == %@", encounterRecordName)
        let query = CKQuery(recordType: CommentRecordMapper.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (results, queryCursor) = try await database.records(matching: query, resultsLimit: 50)

        let comments = results.compactMap { _, result -> EncounterComment? in
            guard case .success(let record) = result else { return nil }
            return CommentRecordMapper.comment(from: record)
        }

        let cursorString = queryCursor != nil ? "has_more" : nil
        return (comments, cursorString)
    }

    public func commentCount(for encounterRecordName: String) -> Int {
        commentCounts[encounterRecordName, default: 0]
    }

    // MARK: - Bulk Load

    public func loadInteractionData(for encounterRecordNames: [String]) async throws {
        guard let userID = getCurrentUserID() else { return }
        guard !encounterRecordNames.isEmpty else { return }

        async let likesResult = fetchLikeCounts(for: encounterRecordNames, userID: userID)
        async let commentsResult = fetchCommentCounts(for: encounterRecordNames)

        let (likeData, commentData) = try await (likesResult, commentsResult)

        for (recordName, count) in likeData.counts {
            likeCounts[recordName] = count
        }
        likedEncounters.formUnion(likeData.userLiked)

        for (recordName, count) in commentData {
            commentCounts[recordName] = count
        }
    }

    // MARK: - Private

    private struct LikeLoadResult {
        var counts: [String: Int] = [:]
        var userLiked: Set<String> = []
    }

    private func fetchLikeCounts(
        for encounterRecordNames: [String],
        userID: String
    ) async throws -> LikeLoadResult {
        let predicate = NSPredicate(format: "encounterRecordName IN %@", encounterRecordNames)
        let query = CKQuery(recordType: LikeRecordMapper.recordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        var result = LikeLoadResult()
        for (_, recordResult) in results {
            guard case .success(let record) = recordResult,
                  let like = LikeRecordMapper.like(from: record) else { continue }
            result.counts[like.encounterRecordName, default: 0] += 1
            if like.userID == userID {
                result.userLiked.insert(like.encounterRecordName)
            }
        }
        return result
    }

    private func fetchCommentCounts(
        for encounterRecordNames: [String]
    ) async throws -> [String: Int] {
        let predicate = NSPredicate(format: "encounterRecordName IN %@", encounterRecordNames)
        let query = CKQuery(recordType: CommentRecordMapper.recordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        var counts: [String: Int] = [:]
        for (_, recordResult) in results {
            guard case .success(let record) = recordResult,
                  let encounterName = record["encounterRecordName"] as? String else { continue }
            counts[encounterName, default: 0] += 1
        }
        return counts
    }

    // MARK: - Debug Seeding

    #if DEBUG
    public func seedFakeInteractions(encounterRecordNames: [String]) {
        guard likeCounts.isEmpty && commentCounts.isEmpty else { return }
        guard !encounterRecordNames.isEmpty else { return }

        let userID = getCurrentUserID() ?? "debug-user"

        for (index, recordName) in encounterRecordNames.prefix(5).enumerated() {
            likeCounts[recordName] = (index + 1) * 2
            commentCounts[recordName] = max(0, index)

            if index % 2 == 0 {
                likedEncounters.insert(recordName)
            }
        }

        // Ensure at least one encounter the user liked
        if let first = encounterRecordNames.first {
            likedEncounters.insert(first)
            _ = userID // suppress unused warning
        }
    }
    #endif
}
