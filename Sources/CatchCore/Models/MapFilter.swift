import Foundation

/// Owner-based filter for map annotations.
public enum MapOwnerFilter: String, CaseIterable, Sendable, Equatable {
    case myCats
    case friendsCats
}

/// Time range filter for map annotations.
public enum MapTimeRange: String, CaseIterable, Sendable, Equatable {
    case last7Days
    case last30Days
    case allTime

    /// The cutoff date for this range, or `nil` for all time.
    public func cutoffDate(from now: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .last7Days:
            return calendar.date(byAdding: .day, value: -7, to: now)
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .allTime:
            return nil
        }
    }
}

/// Holds the current filter selections for the map view.
/// Default state: "My Cats" selected, time range is all time.
public struct MapFilterState: Equatable, Sendable {
    public var ownerFilters: Set<MapOwnerFilter>
    public var timeRange: MapTimeRange

    /// The default owner filters applied on first load.
    public static let defaultOwnerFilters: Set<MapOwnerFilter> = [.myCats]

    public init(
        ownerFilters: Set<MapOwnerFilter> = MapFilterState.defaultOwnerFilters,
        timeRange: MapTimeRange = .allTime
    ) {
        self.ownerFilters = ownerFilters
        self.timeRange = timeRange
    }

    /// Whether any filters differ from the default state.
    public var hasActiveFilters: Bool {
        ownerFilters != Self.defaultOwnerFilters || timeRange != .allTime
    }

    /// Toggles an owner filter on or off.
    public mutating func toggleOwnerFilter(_ filter: MapOwnerFilter) {
        if ownerFilters.contains(filter) {
            ownerFilters.remove(filter)
        } else {
            ownerFilters.insert(filter)
        }
    }

    /// Resets all filters to default.
    public mutating func reset() {
        ownerFilters = Self.defaultOwnerFilters
        timeRange = .allTime
    }
}
