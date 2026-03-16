import Foundation
import Observation
import Supabase

@Observable
@MainActor
public final class SupabaseFollowService: FollowService {
    public private(set) var followers: [Follow] = []
    public private(set) var following: [Follow] = []
    public private(set) var outgoingPending: [Follow] = []
    public private(set) var pendingRequests: [Follow] = []
    public private(set) var isLoading = false
    public private(set) var hasMoreFollowers = false
    public private(set) var hasMoreFollowing = false

    private let repository: any SupabaseFollowRepository
    private let clientProvider: (any SupabaseClientProviding)?
    private let pageSize: Int
    private var realtimeChannel: RealtimeChannelV2?
    private var realtimeTask: Task<Void, Never>?

    public init(
        repository: any SupabaseFollowRepository,
        clientProvider: (any SupabaseClientProviding)? = nil,
        pageSize: Int = PaginationConstants.defaultPageSize
    ) {
        self.repository = repository
        self.clientProvider = clientProvider
        self.pageSize = pageSize
    }

    // MARK: - Follow / Unfollow

    public func follow(targetID: String, by userID: String, isTargetPrivate: Bool) async throws {
        guard userID != targetID else { throw FollowServiceError.cannotFollowSelf }
        guard !isFollowing(targetID) else { throw FollowServiceError.alreadyFollowing }
        guard pendingRequestTo(targetID) == nil else { throw FollowServiceError.requestAlreadyPending }

        let status: FollowStatus = isTargetPrivate ? .pending : .active
        let payload = SupabaseFollowInsertPayload(
            followerID: userID,
            followeeID: targetID,
            status: status.rawValue
        )

        let row = try await repository.insertFollow(payload)
        let follow = row.toDomain()

        if follow.isActive {
            following.append(follow)
        } else {
            outgoingPending.append(follow)
        }
    }

    public func unfollow(targetID: String, by userID: String) async throws {
        guard let match = following.first(where: { $0.followeeID == targetID }) else {
            if let pending = outgoingPending.first(where: { $0.followeeID == targetID }) {
                try await repository.deleteFollow(id: pending.id)
                outgoingPending.removeAll { $0.id == pending.id }
                return
            }
            throw FollowServiceError.followNotFound
        }
        try await repository.deleteFollow(id: match.id)
        following.removeAll { $0.id == match.id }
    }

    // MARK: - Request Management

    public func approveRequest(_ follow: Follow) async throws {
        let updated = try await repository.updateFollowStatus(
            id: follow.id,
            status: FollowStatus.active.rawValue
        )
        pendingRequests.removeAll { $0.id == follow.id }
        followers.append(updated.toDomain())
    }

    public func declineRequest(_ follow: Follow) async throws {
        try await repository.deleteFollow(id: follow.id)
        pendingRequests.removeAll { $0.id == follow.id }
    }

    public func removeFollower(_ follow: Follow) async throws {
        try await repository.deleteFollow(id: follow.id)
        followers.removeAll { $0.id == follow.id }
    }

    // MARK: - Refresh & Pagination

    public func refresh(for userID: String) async throws {
        isLoading = true
        defer { isLoading = false }

        async let activeFollowers = repository.fetchFollowers(
            userID: userID, status: FollowStatus.active.rawValue,
            limit: pageSize, offset: 0
        )
        async let activeFollowing = repository.fetchFollowing(
            userID: userID, status: FollowStatus.active.rawValue,
            limit: pageSize, offset: 0
        )
        async let pendingIn = repository.fetchPendingIncoming(userID: userID)
        async let pendingOut = repository.fetchPendingOutgoing(userID: userID)

        let (fRows, gRows, piRows, poRows) = try await (activeFollowers, activeFollowing, pendingIn, pendingOut)

        followers = fRows.map { $0.toDomain() }
        hasMoreFollowers = fRows.count >= pageSize
        following = gRows.map { $0.toDomain() }
        hasMoreFollowing = gRows.count >= pageSize
        pendingRequests = piRows.map { $0.toDomain() }  // Includes joined display names
        outgoingPending = poRows.map { $0.toDomain() }
    }

    public func loadMoreFollowers(for userID: String) async throws {
        guard hasMoreFollowers else { return }

        let rows = try await repository.fetchFollowers(
            userID: userID, status: FollowStatus.active.rawValue,
            limit: pageSize, offset: followers.count
        )
        let newFollows = rows.map { $0.toDomain() }
        followers.append(contentsOf: newFollows)
        hasMoreFollowers = rows.count >= pageSize
    }

    public func loadMoreFollowing(for userID: String) async throws {
        guard hasMoreFollowing else { return }

        let rows = try await repository.fetchFollowing(
            userID: userID, status: FollowStatus.active.rawValue,
            limit: pageSize, offset: following.count
        )
        let newFollows = rows.map { $0.toDomain() }
        following.append(contentsOf: newFollows)
        hasMoreFollowing = rows.count >= pageSize
    }

    // MARK: - Counts & Lists

    public func fetchFollowCounts(for userID: String) async throws -> (followers: Int, following: Int) {
        async let followerCount = repository.countFollowers(userID: userID)
        async let followingCount = repository.countFollowing(userID: userID)
        return try await (followers: followerCount, following: followingCount)
    }

    public func fetchFollowers(for userID: String) async throws -> [Follow] {
        let rows = try await repository.fetchFollowers(
            userID: userID, status: FollowStatus.active.rawValue,
            limit: 200, offset: 0
        )
        return rows.map { $0.toDomain() }
    }

    public func fetchFollowing(for userID: String) async throws -> [Follow] {
        let rows = try await repository.fetchFollowing(
            userID: userID, status: FollowStatus.active.rawValue,
            limit: 200, offset: 0
        )
        return rows.map { $0.toDomain() }
    }

    // MARK: - Cache Lookups

    public func isFollowing(_ targetID: String) -> Bool {
        following.contains { $0.followeeID == targetID }
    }

    public func pendingRequestTo(_ targetID: String) -> Follow? {
        outgoingPending.first { $0.followeeID == targetID }
    }

    // MARK: - Realtime

    public func startListening(for userID: String) async {
        guard let clientProvider else { return }
        await stopListening()

        let channel = clientProvider.client.channel("follows:\(userID)")
        let insertions: AsyncStream<InsertAction> = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "follows",
            filter: .eq("followee_id", value: userID)
        )

        realtimeChannel = channel
        try? await channel.subscribeWithError()

        realtimeTask = Task { [weak self] in
            for await action in insertions {
                guard let self, !Task.isCancelled else { return }
                await self.handleRealtimeInsert(action, userID: userID)
            }
        }
    }

    public func stopListening() async {
        realtimeTask?.cancel()
        realtimeTask = nil

        if let channel = realtimeChannel {
            await clientProvider?.client.removeChannel(channel)
            realtimeChannel = nil
        }
    }

    private func handleRealtimeInsert(_ action: InsertAction, userID: String) async {
        do {
            let data = try JSONEncoder().encode(action.record)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let follow = try decoder.decode(SupabaseFollow.self, from: data)
            let domain = follow.toDomain()

            guard domain.isPending, !pendingRequests.contains(where: { $0.id == domain.id }) else { return }
            pendingRequests.insert(domain, at: 0)
        } catch {
            // Re-fetch pending list on decode failure to include display names
            let rows = try? await repository.fetchPendingIncoming(userID: userID)
            if let rows {
                pendingRequests = rows.map { $0.toDomain() }
            }
        }
    }

    // MARK: - Debug Seeding

    #if DEBUG
    public func seedFakeFollows(currentUserID: String) {
        guard following.isEmpty && followers.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        following = [
            Follow(id: "\(currentUserID)_fake-tuong", followerID: currentUserID, followeeID: "fake-tuong", status: .active, createdAt: calendar.date(byAdding: .day, value: -20, to: now)!),
            Follow(id: "\(currentUserID)_fake-sophi", followerID: currentUserID, followeeID: "fake-sophi", status: .active, createdAt: calendar.date(byAdding: .day, value: -10, to: now)!),
            Follow(id: "\(currentUserID)_fake-shiv", followerID: currentUserID, followeeID: "fake-shiv", status: .active, createdAt: calendar.date(byAdding: .day, value: -5, to: now)!),
            Follow(id: "\(currentUserID)_fake-mark", followerID: currentUserID, followeeID: "fake-mark", status: .active, createdAt: calendar.date(byAdding: .day, value: -3, to: now)!)
        ]

        followers = [
            Follow(id: "fake-tuong_\(currentUserID)", followerID: "fake-tuong", followeeID: currentUserID, status: .active, createdAt: calendar.date(byAdding: .day, value: -18, to: now)!),
            Follow(id: "fake-tatum_\(currentUserID)", followerID: "fake-tatum", followeeID: currentUserID, status: .active, createdAt: calendar.date(byAdding: .day, value: -7, to: now)!),
            Follow(id: "fake-mark_\(currentUserID)", followerID: "fake-mark", followeeID: currentUserID, status: .active, createdAt: calendar.date(byAdding: .day, value: -2, to: now)!)
        ]

        pendingRequests = [
            Follow(id: "fake-jorge_\(currentUserID)", followerID: "fake-jorge", followeeID: currentUserID, status: .pending, createdAt: calendar.date(byAdding: .day, value: -1, to: now)!)
        ]
    }
    #endif
}
