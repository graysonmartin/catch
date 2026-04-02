import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class DefaultSocialFeedService: SocialFeedService {
    private(set) var remoteEncounters: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = false
    private(set) var hasLoaded = false

    private let repository: any SupabaseFeedRepository
    private let followService: any FollowService
    private let pageSize: Int

    /// ISO 8601 date string of the oldest item in the current feed, used as cursor.
    private var nextCursor: String?

    /// Tracks the record name of the earliest encounter per cat across all fetched pages.
    private var earliestEncounterPerCat: [String: (date: Date, recordID: String)] = [:]

    init(
        repository: any SupabaseFeedRepository,
        followService: any FollowService,
        pageSize: Int = PaginationConstants.defaultPageSize
    ) {
        self.repository = repository
        self.followService = followService
        self.pageSize = pageSize
    }

    func resetState() {
        remoteEncounters = []
        nextCursor = nil
        earliestEncounterPerCat = [:]
        hasMorePages = false
        hasLoaded = false
        isLoading = false
        isLoadingMore = false
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        let followedIDs = followService.following.map(\.followeeID)
        guard !followedIDs.isEmpty else {
            remoteEncounters = []
            nextCursor = nil
            earliestEncounterPerCat = [:]
            hasMorePages = false
            hasLoaded = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let rows = try await repository.fetchFeed(
                followedUserIDs: followedIDs,
                limit: pageSize,
                cursor: nil
            )
            earliestEncounterPerCat = [:]
            remoteEncounters = mapRows(rows)
            nextCursor = cursorFromRows(rows)
            hasMorePages = rows.count >= pageSize
            hasLoaded = true
        } catch {
            remoteEncounters = []
            nextCursor = nil
            hasMorePages = false
        }
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }

        let followedIDs = followService.following.map(\.followeeID)
        guard !followedIDs.isEmpty else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let rows = try await repository.fetchFeed(
                followedUserIDs: followedIDs,
                limit: pageSize,
                cursor: nextCursor
            )

            let newItems = mapRows(rows)
            remoteEncounters.append(contentsOf: newItems)
            nextCursor = cursorFromRows(rows)
            hasMorePages = rows.count >= pageSize
        } catch {
            hasMorePages = false
        }
    }

    // MARK: - Private

    /// Maps a batch of rows to feed items, tracking earliest encounter per cat
    /// across all pages. Rows within each page arrive in date-descending order,
    /// so each new page contains older encounters that may update the earliest tracker.
    private func mapRows(_ rows: [SupabaseFeedRow]) -> [FeedItem] {
        // First pass: update earliest encounter tracker with this batch.
        for row in rows {
            let catKey = row.catID.uuidString
            let encounterID = row.id.uuidString
            if let existing = earliestEncounterPerCat[catKey] {
                if row.date < existing.date {
                    earliestEncounterPerCat[catKey] = (row.date, encounterID)
                }
            } else {
                earliestEncounterPerCat[catKey] = (row.date, encounterID)
            }
        }

        // Second pass: build feed items using the updated tracker.
        return rows.map { row in
            let encounter = SupabaseFeedMapper.toCloudEncounter(row)
            let cat = SupabaseFeedMapper.toCloudCat(row.cat, ownerID: row.ownerID.uuidString)
            let owner = SupabaseFeedMapper.toCloudUserProfile(row.owner)
            let isFirst = earliestEncounterPerCat[row.catID.uuidString]?.recordID == row.id.uuidString
            return .remote(encounter, cat: cat, owner: owner, isFirstEncounter: isFirst)
        }
    }

    private static let iso8601Formatter = ISO8601DateFormatter()

    private func cursorFromRows(_ rows: [SupabaseFeedRow]) -> String? {
        guard let last = rows.last else { return nil }
        return Self.iso8601Formatter.string(from: last.date)
    }
}
