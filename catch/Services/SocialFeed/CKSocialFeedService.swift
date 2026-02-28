import Foundation
import Observation
import CatchCore

@Observable
@MainActor
final class CKSocialFeedService: SocialFeedService {
    private(set) var remoteEncounters: [FeedItem] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMorePages = false

    private let followService: any FollowService
    private let userBrowseService: any UserBrowseService

    /// All fetched items before pagination slicing — kept in memory for load-more.
    private var allFetchedItems: [FeedItem] = []
    private var displayedCount = 0

    init(
        followService: any FollowService,
        userBrowseService: any UserBrowseService
    ) {
        self.followService = followService
        self.userBrowseService = userBrowseService
    }

    func refresh() async {
        let activeFollows = followService.following
        guard !activeFollows.isEmpty else {
            remoteEncounters = []
            allFetchedItems = []
            displayedCount = 0
            hasMorePages = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        let userIDs = activeFollows.map(\.followeeID)

        var allItems: [FeedItem] = []

        await withTaskGroup(of: [FeedItem].self) { group in
            for userID in userIDs {
                group.addTask { [userBrowseService] in
                    do {
                        let data = try await userBrowseService.fetchUserData(userID: userID)
                        let capped = Array(
                            data.encounters
                                .sorted { $0.date > $1.date }
                                .prefix(PaginationConstants.maxEncountersPerUser)
                        )
                        let earliestByCat = Dictionary(grouping: data.encounters, by: \.catRecordName)
                            .compactMapValues { $0.min(by: { $0.date < $1.date })?.recordName }

                        return capped.map { encounter in
                            let cat = data.cats.first { $0.recordName == encounter.catRecordName }
                            let isFirst = earliestByCat[encounter.catRecordName] == encounter.recordName
                            return FeedItem.remote(encounter, cat: cat, owner: data.profile, isFirstEncounter: isFirst)
                        }
                    } catch {
                        return []
                    }
                }
            }

            for await items in group {
                allItems.append(contentsOf: items)
            }
        }

        allFetchedItems = allItems.sorted { $0.date > $1.date }
        displayedCount = min(PaginationConstants.defaultPageSize, allFetchedItems.count)
        remoteEncounters = Array(allFetchedItems.prefix(displayedCount))
        hasMorePages = displayedCount < allFetchedItems.count
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextCount = min(
            displayedCount + PaginationConstants.defaultPageSize,
            allFetchedItems.count
        )
        displayedCount = nextCount
        remoteEncounters = Array(allFetchedItems.prefix(displayedCount))
        hasMorePages = displayedCount < allFetchedItems.count
    }
}
