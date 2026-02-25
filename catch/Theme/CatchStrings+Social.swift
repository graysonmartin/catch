import Foundation

extension CatchStrings {

    enum Social {
        // SocialView
        static let requests = String(localized: "requests")
        static let findPeople = String(localized: "find people")
        static let noFollowersTitle = String(localized: "no followers yet")
        static let noFollowersSubtitle = String(localized: "your adoring public hasn't arrived")
        static let notFollowingTitle = String(localized: "not following anyone")
        static let notFollowingSubtitle = String(localized: "find some people to follow and start building your circle")

        // SocialTab display names
        static let followersTab = String(localized: "followers")
        static let followingTab = String(localized: "following")

        // FindPeopleView
        static let noOneFound = String(localized: "no one found")
        static let tryDifferentName = String(localized: "try a different name")
        static let findYourPeople = String(localized: "find your people")
        static let findPeopleSubtitle = String(localized: "search by name to discover other cat spotters")
        static let searchByName = String(localized: "search by name")
        static let anonymous = String(localized: "anonymous")
        static let you = String(localized: "you")
        static let followingStatus = String(localized: "following")
        static let requestedStatus = String(localized: "requested")
        static let request = String(localized: "request")
        static let follow = String(localized: "follow")

        // UserPublicProfileView
        static let loadingProfile = String(localized: "loading profile...")
        static let tryAgain = String(localized: "try again")
        static let profileIsPrivate = String(localized: "this profile is private")
        static let followToSee = String(localized: "follow them to see their cats")
        static let noCatsYetTitle = String(localized: "no cats yet")
        static let noCatsYetSubtitle = String(localized: "this person hasn't logged any cats")
        static let noActivityTitle = String(localized: "no activity yet")
        static let noActivitySubtitle = String(localized: "no encounters to show")
        static let profileFallbackTitle = String(localized: "profile")
        static let statPlaceholder = String(localized: "--")

        // ProfileTab display names
        static let catsTab = String(localized: "cats")
        static let activityTab = String(localized: "activity")

        // FollowRowView
        static let removeFollower = String(localized: "remove follower")
        static let unfollow = String(localized: "unfollow")
        static let areYouSure = String(localized: "are you sure?")

        static func since(_ date: Date) -> String {
            let formatted = date.formatted(.dateTime.month(.abbreviated).year())
            return String(localized: "since \(formatted)")
        }

        // PendingRequestRowView
        static let wantsToFollowYou = String(localized: "wants to follow you")

        // RemoteFeedItemView
        static let unknownCat = String(localized: "unknown cat")
    }
}
