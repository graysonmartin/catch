import Foundation
import Observation
import Supabase

@Observable
@MainActor
public final class SupabaseSocialInteractionService: SocialInteractionService {
    public private(set) var likeCounts: [String: Int] = [:]
    public private(set) var commentCounts: [String: Int] = [:]
    public private(set) var likedEncounters: Set<String> = []

    private let repository: any SupabaseSocialRepository
    private let clientProvider: (any SupabaseClientProviding)?
    private let getCurrentUserID: () -> String?
    private let pageSize: Int

    private var realtimeLikesChannel: RealtimeChannelV2?
    private var realtimeCommentsChannel: RealtimeChannelV2?
    private var realtimeLikesTask: Task<Void, Never>?
    private var realtimeCommentsTask: Task<Void, Never>?

    /// Encounter IDs the current user owns, used to filter realtime events.
    private var ownedEncounterIDs: Set<String> = []

    public init(
        repository: any SupabaseSocialRepository,
        clientProvider: (any SupabaseClientProviding)? = nil,
        getCurrentUserID: @escaping @Sendable () -> String?,
        pageSize: Int = PaginationConstants.defaultPageSize
    ) {
        self.repository = repository
        self.clientProvider = clientProvider
        self.getCurrentUserID = getCurrentUserID
        self.pageSize = pageSize
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
                try await repository.deleteLike(
                    encounterID: encounterRecordName,
                    userID: userID
                )
            } else {
                _ = try await repository.insertLike(
                    encounterID: encounterRecordName,
                    userID: userID
                )
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
            throw SocialInteractionError.networkError(error.localizedDescription)
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
        let offset = cursor.flatMap(Int.init) ?? 0

        let rows = try await repository.fetchLikes(
            encounterID: encounterRecordName,
            limit: pageSize,
            offset: offset
        )

        let users = rows.map { $0.toLikedByUser() }
        let nextCursor: String? = rows.count >= pageSize
            ? String(offset + rows.count)
            : nil

        return (users, nextCursor)
    }

    // MARK: - Comments

    public func addComment(
        encounterRecordName: String,
        text: String
    ) async throws -> EncounterComment {
        guard let userID = getCurrentUserID() else {
            throw SocialInteractionError.notSignedIn
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SocialInteractionError.commentEmpty }
        guard trimmed.count <= TextInputLimits.comment else {
            throw SocialInteractionError.commentTooLong
        }

        let row = try await repository.insertComment(
            encounterID: encounterRecordName,
            userID: userID,
            text: trimmed
        )

        commentCounts[encounterRecordName, default: 0] += 1
        return row.toDomain()
    }

    public func deleteComment(
        recordName: String,
        encounterRecordName: String
    ) async throws {
        guard getCurrentUserID() != nil else {
            throw SocialInteractionError.notSignedIn
        }

        try await repository.deleteComment(id: recordName)
        commentCounts[encounterRecordName, default: 1] -= 1
    }

    public func fetchComments(
        encounterRecordName: String,
        cursor: String?
    ) async throws -> ([EncounterComment], String?) {
        let offset = cursor.flatMap(Int.init) ?? 0

        let rows = try await repository.fetchComments(
            encounterID: encounterRecordName,
            limit: pageSize,
            offset: offset
        )

        let comments = rows.map { $0.toDomain() }
        let nextCursor: String? = rows.count >= pageSize
            ? String(offset + rows.count)
            : nil

        return (comments, nextCursor)
    }

    public func commentCount(for encounterRecordName: String) -> Int {
        commentCounts[encounterRecordName, default: 0]
    }

    // MARK: - Bulk Load

    public func loadInteractionData(
        for encounterRecordNames: [String]
    ) async throws {
        guard let userID = getCurrentUserID() else { return }
        guard !encounterRecordNames.isEmpty else { return }

        async let countsResult = repository.fetchInteractionCounts(
            encounterIDs: encounterRecordNames
        )
        async let userLikesResult = repository.fetchUserLikes(
            encounterIDs: encounterRecordNames,
            userID: userID
        )

        let (counts, userLikes) = try await (countsResult, userLikesResult)

        for row in counts {
            let encounterID = row.id.uuidString.lowercased()
            likeCounts[encounterID] = row.likeCount
            commentCounts[encounterID] = row.commentCount
        }

        let likedIDs = Set(userLikes.map { $0.encounterID.uuidString.lowercased() })
        likedEncounters.formUnion(likedIDs)
    }

    // MARK: - Realtime

    /// Registers encounter IDs owned by the current user for realtime filtering.
    public func registerOwnedEncounters(_ encounterIDs: Set<String>) {
        ownedEncounterIDs = encounterIDs
    }

    /// Starts listening for new likes and comments on owned encounters.
    public func startListening() async {
        guard let clientProvider else { return }
        await stopListening()

        await startLikesListener(clientProvider: clientProvider)
        await startCommentsListener(clientProvider: clientProvider)
    }

    /// Stops all realtime subscriptions.
    public func stopListening() async {
        realtimeLikesTask?.cancel()
        realtimeLikesTask = nil
        realtimeCommentsTask?.cancel()
        realtimeCommentsTask = nil

        if let channel = realtimeLikesChannel {
            await clientProvider?.client.removeChannel(channel)
            realtimeLikesChannel = nil
        }
        if let channel = realtimeCommentsChannel {
            await clientProvider?.client.removeChannel(channel)
            realtimeCommentsChannel = nil
        }
    }

    private func startLikesListener(
        clientProvider: any SupabaseClientProviding
    ) async {
        let channel = clientProvider.client.channel("encounter_likes_rt")
        let insertions: AsyncStream<InsertAction> = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "encounter_likes"
        )
        let deletions: AsyncStream<DeleteAction> = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "encounter_likes"
        )

        realtimeLikesChannel = channel
        try? await channel.subscribeWithError()

        realtimeLikesTask = Task { [weak self] in
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await action in insertions {
                        guard let self, !Task.isCancelled else { return }
                        await self.handleLikeInsert(action)
                    }
                }
                group.addTask {
                    for await action in deletions {
                        guard let self, !Task.isCancelled else { return }
                        await self.handleLikeDelete(action)
                    }
                }
            }
        }
    }

    private func startCommentsListener(
        clientProvider: any SupabaseClientProviding
    ) async {
        let channel = clientProvider.client.channel("encounter_comments_rt")
        let insertions: AsyncStream<InsertAction> = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "encounter_comments"
        )

        realtimeCommentsChannel = channel
        try? await channel.subscribeWithError()

        realtimeCommentsTask = Task { [weak self] in
            for await action in insertions {
                guard let self, !Task.isCancelled else { return }
                await self.handleCommentInsert(action)
            }
        }
    }

    private func handleLikeInsert(_ action: InsertAction) {
        guard let encounterID = action.record["encounter_id"]?.stringValue,
              ownedEncounterIDs.contains(encounterID) else { return }
        likeCounts[encounterID, default: 0] += 1
    }

    private func handleLikeDelete(_ action: DeleteAction) {
        guard let encounterID = action.oldRecord["encounter_id"]?.stringValue,
              ownedEncounterIDs.contains(encounterID) else { return }
        likeCounts[encounterID, default: 1] -= 1
    }

    private func handleCommentInsert(_ action: InsertAction) {
        guard let encounterID = action.record["encounter_id"]?.stringValue,
              ownedEncounterIDs.contains(encounterID) else { return }
        commentCounts[encounterID, default: 0] += 1
    }
}
