import Foundation
import CatchCore

extension CatchStrings {

    enum Social {
        // SocialView
        static let requests = String(localized: "requests")
        static let findPeople = String(localized: "find people")
        static let noFollowersTitle = String(localized: "no followers yet")
        static let noFollowersSubtitle = String(localized: "share your profile to get some")
        static let notFollowingTitle = String(localized: "not following anyone")
        static let notFollowingSubtitle = String(localized: "search for people to see their cats in your feed")
        static let remoteNoFollowers = String(localized: "no followers to show")
        static let remoteNotFollowing = String(localized: "not following anyone yet")

        // SocialTab display names
        static let followersTab = String(localized: "followers")
        static let followingTab = String(localized: "following")

        // FindPeopleView
        static let noOneFound = String(localized: "no one found")
        static let tryDifferentUsername = String(localized: "try a different username")
        static let findYourPeople = String(localized: "find your people")
        static let findPeopleSubtitle = String(localized: "search by username to discover other cat spotters")
        static let searchByUsername = String(localized: "search by username")
        static let anonymous = String(localized: "anonymous")
        static let you = String(localized: "you")
        static let followingStatus = String(localized: "following")
        static let requestedStatus = String(localized: "requested")
        static let request = String(localized: "request")
        static let follow = String(localized: "follow")

        // RemoteProfileContent
        static let loadingProfile = String(localized: "loading profile...")
        static let tryAgain = String(localized: "try again")
        static let profileIsPrivate = String(localized: "this profile is private")
        static let followToSee = String(localized: "follow them to see their cats")
        static let noCatsYetTitle = String(localized: "no cats yet")
        static let noCatsYetSubtitle = String(localized: "this person hasn't logged any cats")
        static let noActivityTitle = String(localized: "no diary entries")
        static let noActivitySubtitle = String(localized: "they haven't written anything down yet")
        static let profileFallbackTitle = String(localized: "profile")
        static let statPlaceholder = String(localized: "--")

        // FollowRowView
        static let removeFollower = String(localized: "remove follower")
        static let unfollow = String(localized: "unfollow")
        static let areYouSure = String(localized: "are you sure?")
        static let unfollowConfirmMessage = String(localized: "you'll stop seeing their posts in your feed")

        // PendingRequestRowView
        static let wantsToFollowYou = String(localized: "wants to follow you")

        // Display name loading placeholder
        static let loadingName = String(localized: "loading...")

        // RemoteFeedItemView
        static let unknownCat = String(localized: "unknown cat")
    }
}
