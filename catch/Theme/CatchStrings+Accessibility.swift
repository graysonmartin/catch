import Foundation
import CatchCore

extension CatchStrings {

    enum Accessibility {
        // MARK: - Photos
        static func catPhoto(name: String) -> String {
            String(localized: "Photo of \(name)")
        }
        static let catPhotoPlaceholder = String(localized: "No photo available")
        static func photoCarouselLabel(count: Int) -> String {
            String(localized: "Photo carousel, \(count) photo\(count == 1 ? "" : "s")")
        }
        static let photoPlaceholder = String(localized: "No photo")
        static func photoPage(_ current: Int, of total: Int) -> String {
            String(localized: "Photo \(current) of \(total)")
        }

        // MARK: - Feed
        static let feedCardHint = String(localized: "Double tap for details")
        static let moreOptions = String(localized: "More options")
        static let ownedCat = String(localized: "Owned cat")
        static func encounterPill(_ text: String) -> String {
            String(localized: "\(text) encounter")
        }

        // MARK: - Interaction
        static let likeButton = String(localized: "Like")
        static let unlikeButton = String(localized: "Unlike")
        static func likeCount(_ count: Int) -> String {
            String(localized: "\(count) like\(count == 1 ? "" : "s"), double tap to view")
        }
        static func commentButton(_ count: Int) -> String {
            count == 0
                ? String(localized: "Add comment")
                : String(localized: "\(count) comment\(count == 1 ? "" : "s"), double tap to view")
        }
        static let submitComment = String(localized: "Submit comment")
        static let deleteComment = String(localized: "Delete comment")

        // MARK: - Map
        static func mapPin(catName: String) -> String {
            String(localized: "Map pin for \(catName)")
        }
        static func mapCluster(count: Int) -> String {
            String(localized: "Cluster of \(count) cats, double tap to zoom in")
        }
        static func mapOverflow(count: Int) -> String {
            String(localized: "\(count) more cats, double tap to view list")
        }
        static let mapFilterButton = String(localized: "Map filters")
        static let mapFilterButtonActiveHint = String(localized: "Filters active")
        static let closeFilters = String(localized: "Close filters")
        static let hiddenCatsBanner = String(localized: "Some cats not shown on map, double tap for details")

        // MARK: - Profile
        static func userAvatar(name: String) -> String {
            String(localized: "Profile photo of \(name)")
        }
        static let userAvatarPlaceholder = String(localized: "Default profile photo")
        static func statCard(count: Int, label: String) -> String {
            String(localized: "\(count) \(label)")
        }
        static func followerCount(_ count: Int) -> String {
            String(localized: "\(count) follower\(count == 1 ? "" : "s")")
        }
        static func followerCountWithPending(_ followers: Int, pending: Int) -> String {
            String(localized: "\(followers) follower\(followers == 1 ? "" : "s"), \(pending) pending request\(pending == 1 ? "" : "s")")
        }
        static func followingCount(_ count: Int) -> String {
            String(localized: "Following \(count)")
        }
        static func pendingRequests(_ count: Int) -> String {
            String(localized: "\(count) pending request\(count == 1 ? "" : "s")")
        }
        static let findPeople = String(localized: "Find people")
        static let editProfile = String(localized: "Edit profile")
        static let settings = String(localized: "Settings")

        // MARK: - Breed Log
        static func breedCard(name: String, rarity: String) -> String {
            String(localized: "\(name), \(rarity) rarity")
        }
        static let undiscoveredBreed = String(localized: "Undiscovered breed")
        static func breedProgress(discovered: Int, total: Int) -> String {
            String(localized: "\(discovered) of \(total) breeds discovered")
        }

        // MARK: - Collection
        static let unknownBreed = String(localized: "unknown breed")
        static func catCard(name: String, breed: String, encounters: Int) -> String {
            String(localized: "\(name), \(breed.isEmpty ? unknownBreed : breed), \(encounters) encounter\(encounters == 1 ? "" : "s")")
        }

        // MARK: - Loading & Toasts
        static let loading = String(localized: "Loading")
        static let dismissToast = String(localized: "Dismiss notification")
        static let retryAction = String(localized: "Retry")

        // MARK: - Engagement
        static func engagement(likes: Int, comments: Int) -> String {
            switch (likes > 0, comments > 0) {
            case (true, true):
                String(localized: "\(likes) like\(likes == 1 ? "" : "s"), \(comments) comment\(comments == 1 ? "" : "s")")
            case (true, false):
                String(localized: "\(likes) like\(likes == 1 ? "" : "s")")
            case (false, true):
                String(localized: "\(comments) comment\(comments == 1 ? "" : "s")")
            case (false, false):
                ""
            }
        }

        // MARK: - Onboarding
        static func onboardingPage(_ current: Int, of total: Int) -> String {
            String(localized: "Page \(current) of \(total)")
        }

        // MARK: - Steven Badge
        static let stevenBadge = String(localized: "Steven, the mascot cat")

        // MARK: - Follow Requests
        static let approveRequest = String(localized: "Approve follow request")
        static let declineRequest = String(localized: "Decline follow request")
    }
}
