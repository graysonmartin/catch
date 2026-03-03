import Foundation

/// Default page sizes for paginated queries throughout the app.
public enum PaginationConstants {
    /// Default page size for most lists (feed, followers, following).
    public static let defaultPageSize = 20

    /// Page size for comment threads.
    public static let commentsPageSize = 20

    /// Maximum encounters fetched per user in the social feed.
    public static let maxEncountersPerUser = 20
}
