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

    /// Stores active CK cursors keyed by encounter record name for comment pagination.
    private var commentCursors: [String: CKQueryOperation.Cursor] = [:]

    /// Stores active CK cursors keyed by encounter record name for like pagination.
    private var likeCursors: [String: CKQueryOperation.Cursor] = [:]

    /// Local cache of fetched comments, keyed by encounter record name.
    private var commentCache: [String: [EncounterComment]] = [:]

    /// Local cache of fetched liked-by users, keyed by encounter record name.
    private var likeCache: [String: [LikedByUser]] = [:]

    private let cloudKitService: (any CloudKitService)?

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    public init(
        getCurrentUserID: @escaping @Sendable () -> String?,
        cloudKitService: (any CloudKitService)? = nil
    ) {
        self.getCurrentUserID = getCurrentUserID
        self.cloudKitService = cloudKitService
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

        // Invalidate cached like list so it's re-fetched with current state
        likeCache.removeValue(forKey: encounterRecordName)

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

    public func fetchLikes(
        encounterRecordName: String,
        cursor: String?
    ) async throws -> ([LikedByUser], String?) {
        // Return cached data if available and this is the first page
        if cursor == nil, let cached = likeCache[encounterRecordName] {
            let page = Array(cached.prefix(PaginationConstants.likesPageSize))
            let hasMore = cached.count > PaginationConstants.likesPageSize
            return (page, hasMore ? "has_more" : nil)
        }

        let results: [(CKRecord.ID, Result<CKRecord, any Error>)]
        let queryCursor: CKQueryOperation.Cursor?

        if cursor != nil, let activeCursor = likeCursors[encounterRecordName] {
            (results, queryCursor) = try await database.records(
                continuingMatchFrom: activeCursor,
                resultsLimit: PaginationConstants.likesPageSize
            )
        } else {
            let predicate = NSPredicate(format: "encounterRecordName == %@", encounterRecordName)
            let query = CKQuery(recordType: LikeRecordMapper.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            (results, queryCursor) = try await database.records(
                matching: query,
                resultsLimit: PaginationConstants.likesPageSize
            )
        }

        let likes = results.compactMap { _, result -> EncounterLike? in
            guard case .success(let record) = result else { return nil }
            return LikeRecordMapper.like(from: record)
        }

        if let queryCursor {
            likeCursors[encounterRecordName] = queryCursor
        } else {
            likeCursors.removeValue(forKey: encounterRecordName)
        }

        let cursorString: String? = queryCursor != nil ? "has_more" : nil

        let users = await resolveLikeUsers(likes)

        // Cache the first page results
        if cursor == nil {
            likeCache[encounterRecordName] = users
        }

        return (users, cursorString)
    }

    /// Resolves EncounterLike records into LikedByUser models by fetching profile data.
    private func resolveLikeUsers(_ likes: [EncounterLike]) async -> [LikedByUser] {
        await withTaskGroup(of: LikedByUser?.self) { group in
            for like in likes {
                group.addTask { [cloudKitService] in
                    let profile = try? await cloudKitService?.fetchUserProfile(appleUserID: like.userID)
                    return LikedByUser(
                        id: like.id,
                        userID: like.userID,
                        displayName: profile?.displayName ?? like.userID.prefix(8).description,
                        username: profile?.username,
                        likedAt: like.createdAt
                    )
                }
            }

            var users: [LikedByUser] = []
            for await user in group {
                if let user {
                    users.append(user)
                }
            }
            return users.sorted { $0.likedAt > $1.likedAt }
        }
    }

    /// Resolves display names for comment authors by fetching profile data.
    private func resolveCommentAuthors(_ comments: [EncounterComment]) async -> [EncounterComment] {
        let uniqueUserIDs = Set(comments.map(\.userID))
        var profilesByID: [String: CloudUserProfile] = [:]

        await withTaskGroup(of: (String, CloudUserProfile?).self) { group in
            for userID in uniqueUserIDs {
                group.addTask { [cloudKitService] in
                    let profile = try? await cloudKitService?.fetchUserProfile(appleUserID: userID)
                    return (userID, profile)
                }
            }
            for await (userID, profile) in group {
                profilesByID[userID] = profile
            }
        }

        return comments.map { comment in
            let profile = profilesByID[comment.userID]
            return EncounterComment(
                id: comment.id,
                encounterRecordName: comment.encounterRecordName,
                userID: comment.userID,
                displayName: profile?.displayName ?? comment.displayName,
                text: comment.text,
                createdAt: comment.createdAt,
                isPending: comment.isPending
            )
        }
    }

    // MARK: - Comments

    public func addComment(encounterRecordName: String, text: String) async throws -> EncounterComment {
        guard let userID = getCurrentUserID() else {
            throw SocialInteractionError.notSignedIn
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SocialInteractionError.commentEmpty }
        guard trimmed.count <= TextInputLimits.comment else { throw SocialInteractionError.commentTooLong }

        let profile = try? await cloudKitService?.fetchUserProfile(appleUserID: userID)

        let comment = EncounterComment(
            id: "\(userID)_comment_\(UUID().uuidString)",
            encounterRecordName: encounterRecordName,
            userID: userID,
            displayName: profile?.displayName,
            text: trimmed,
            createdAt: Date()
        )

        let record = CommentRecordMapper.record(from: comment)
        _ = try await database.save(record)

        commentCounts[encounterRecordName, default: 0] += 1
        // Invalidate cache so next fetch gets fresh data from CloudKit
        commentCache.removeValue(forKey: encounterRecordName)
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
        // Invalidate cache so next fetch gets fresh data from CloudKit
        commentCache.removeValue(forKey: encounterRecordName)
    }

    public func fetchComments(
        encounterRecordName: String,
        cursor: String?
    ) async throws -> ([EncounterComment], String?) {
        // Return cached data if available and this is the first page
        if cursor == nil, let cached = commentCache[encounterRecordName] {
            let page = Array(cached.prefix(PaginationConstants.commentsPageSize))
            let hasMore = cached.count > PaginationConstants.commentsPageSize
            return (page, hasMore ? "has_more" : nil)
        }

        let results: [(CKRecord.ID, Result<CKRecord, any Error>)]
        let queryCursor: CKQueryOperation.Cursor?

        if cursor != nil, let activeCursor = commentCursors[encounterRecordName] {
            (results, queryCursor) = try await database.records(
                continuingMatchFrom: activeCursor,
                resultsLimit: PaginationConstants.commentsPageSize
            )
        } else {
            let predicate = NSPredicate(format: "encounterRecordName == %@", encounterRecordName)
            let query = CKQuery(recordType: CommentRecordMapper.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            (results, queryCursor) = try await database.records(
                matching: query,
                resultsLimit: PaginationConstants.commentsPageSize
            )
        }

        var comments = results.compactMap { _, result -> EncounterComment? in
            guard case .success(let record) = result else { return nil }
            return CommentRecordMapper.comment(from: record)
        }

        // Resolve display names for comment authors
        comments = await resolveCommentAuthors(comments)

        if let queryCursor {
            commentCursors[encounterRecordName] = queryCursor
        } else {
            commentCursors.removeValue(forKey: encounterRecordName)
        }

        let cursorString: String? = queryCursor != nil ? "has_more" : nil

        // Cache the first page results
        if cursor == nil {
            commentCache[encounterRecordName] = comments
        }

        return (comments, cursorString)
    }

    public func commentCount(for encounterRecordName: String) -> Int {
        commentCounts[encounterRecordName, default: 0]
    }

    // MARK: - Bulk Load

    public func loadInteractionData(for encounterRecordNames: [String]) async throws {
        guard let userID = getCurrentUserID() else { return }
        guard !encounterRecordNames.isEmpty else { return }

        async let likesResult = fetchLikeData(for: encounterRecordNames, userID: userID)
        async let commentsResult = fetchCommentData(for: encounterRecordNames)

        let (likeData, commentData) = try await (likesResult, commentsResult)

        for (recordName, count) in likeData.counts {
            likeCounts[recordName] = count
        }
        likedEncounters.formUnion(likeData.userLiked)

        for (recordName, likes) in likeData.likesByEncounter {
            likeCache[recordName] = likes
        }

        for (recordName, count) in commentData.counts {
            commentCounts[recordName] = count
        }

        for (recordName, comments) in commentData.commentsByEncounter {
            commentCache[recordName] = comments
        }
    }

    // MARK: - Private

    private struct LikeLoadResult {
        var counts: [String: Int] = [:]
        var userLiked: Set<String> = []
        var likesByEncounter: [String: [LikedByUser]] = [:]
    }

    private struct CommentLoadResult {
        var counts: [String: Int] = [:]
        var commentsByEncounter: [String: [EncounterComment]] = [:]
    }

    private func fetchLikeData(
        for encounterRecordNames: [String],
        userID: String
    ) async throws -> LikeLoadResult {
        let predicate = NSPredicate(format: "encounterRecordName IN %@", encounterRecordNames)
        let query = CKQuery(recordType: LikeRecordMapper.recordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        var result = LikeLoadResult()
        var likesByEncounter: [String: [EncounterLike]] = [:]
        for (_, recordResult) in results {
            guard case .success(let record) = recordResult,
                  let like = LikeRecordMapper.like(from: record) else { continue }
            result.counts[like.encounterRecordName, default: 0] += 1
            likesByEncounter[like.encounterRecordName, default: []].append(like)
            if like.userID == userID {
                result.userLiked.insert(like.encounterRecordName)
            }
        }

        // Resolve likes into LikedByUser models grouped by encounter
        for (encounterName, likes) in likesByEncounter {
            let users = await resolveLikeUsers(likes)
            result.likesByEncounter[encounterName] = users
        }

        return result
    }

    private func fetchCommentData(
        for encounterRecordNames: [String]
    ) async throws -> CommentLoadResult {
        let predicate = NSPredicate(format: "encounterRecordName IN %@", encounterRecordNames)
        let query = CKQuery(recordType: CommentRecordMapper.recordType, predicate: predicate)

        let (results, _) = try await database.records(matching: query, resultsLimit: 200)

        var allComments: [EncounterComment] = []
        var countsByEncounter: [String: Int] = [:]
        for (_, recordResult) in results {
            guard case .success(let record) = recordResult,
                  let comment = CommentRecordMapper.comment(from: record) else { continue }
            countsByEncounter[comment.encounterRecordName, default: 0] += 1
            allComments.append(comment)
        }

        // Resolve display names for all comment authors in one batch
        let resolved = await resolveCommentAuthors(allComments)

        var result = CommentLoadResult()
        result.counts = countsByEncounter
        for comment in resolved {
            result.commentsByEncounter[comment.encounterRecordName, default: []].append(comment)
        }

        // Sort comments by date descending within each encounter
        for (encounterName, comments) in result.commentsByEncounter {
            result.commentsByEncounter[encounterName] = comments.sorted { $0.createdAt > $1.createdAt }
        }

        return result
    }

    // MARK: - Debug Seeding

    #if DEBUG
    public func seedFakeInteractions(encounterRecordNames: [String]) {
        guard likeCounts.isEmpty && commentCounts.isEmpty else { return }
        guard !encounterRecordNames.isEmpty else { return }

        let userID = getCurrentUserID() ?? "debug-user"
        let names = ["tuong", "sophi", "mark", "shiv", "jordan", "riley"]
        let usernames: [String?] = ["tuong_cats", "sophi_vibes", "mark_the_cat_guy", "shiv_private", nil, "riley_meows"]
        let commentTexts = [
            "what a legend", "this cat runs the block", "obsessed",
            "adding this one to my must-find list", "the energy is immaculate",
        ]

        for (index, recordName) in encounterRecordNames.prefix(5).enumerated() {
            let numLikes = (index + 1) * 2
            let numComments = max(0, index)
            likeCounts[recordName] = numLikes
            commentCounts[recordName] = numComments

            if index % 2 == 0 { likedEncounters.insert(recordName) }

            likeCache[recordName] = (0..<numLikes).map { i in
                let isCurrentUser = i == 0 && index % 2 == 0
                let uid = isCurrentUser ? userID : "fake-\(names[i % names.count])"
                return LikedByUser(
                    id: "\(uid)_like_\(recordName)", userID: uid,
                    displayName: isCurrentUser ? "you" : names[i % names.count],
                    username: isCurrentUser ? nil : usernames[i % usernames.count],
                    likedAt: Date().addingTimeInterval(Double(-i * 3600))
                )
            }

            commentCache[recordName] = (0..<numComments).map { i in
                let uid = "fake-\(names[i % names.count])"
                return EncounterComment(
                    id: "\(uid)_comment_\(recordName)_\(i)",
                    encounterRecordName: recordName, userID: uid,
                    displayName: names[i % names.count],
                    text: commentTexts[i % commentTexts.count],
                    createdAt: Date().addingTimeInterval(Double(-i * 7200))
                )
            }
        }

        if let first = encounterRecordNames.first {
            likedEncounters.insert(first)
        }
    }
    #endif
}
