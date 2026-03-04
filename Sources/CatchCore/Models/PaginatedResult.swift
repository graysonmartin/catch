import Foundation

/// A generic container for cursor-based paginated results from CloudKit queries.
public struct PaginatedResult<T: Sendable>: Sendable {
    public let items: [T]
    public let hasMore: Bool

    public init(items: [T], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}
