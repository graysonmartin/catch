import Foundation
import Observation
import CatchCore

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

        remoteEncounters = allItems
    }
}
