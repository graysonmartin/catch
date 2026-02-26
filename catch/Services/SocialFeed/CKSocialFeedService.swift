import Foundation
import Observation

@Observable
@MainActor
final class CKSocialFeedService: SocialFeedService {
    private(set) var remoteEncounters: [FeedItem] = []
    private(set) var isLoading = false

    private let followService: any FollowService
    private let userBrowseService: any UserBrowseService

    private static let maxEncountersPerUser = 20

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
                                .prefix(CKSocialFeedService.maxEncountersPerUser)
                        )
                        return capped.map { encounter in
                            let cat = data.cats.first { $0.recordName == encounter.catRecordName }
                            return FeedItem.remote(encounter, cat: cat, owner: data.profile)
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

        remoteEncounters = allItems
    }
}
