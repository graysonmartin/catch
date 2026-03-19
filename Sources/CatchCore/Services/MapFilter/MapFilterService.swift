import Foundation

/// Pure-logic filtering for map pins.
/// Stateless — takes filter state and pin metadata, returns whether each pin passes.
public enum MapFilterService {

    /// Determines whether a local (user-owned) cat passes the current filters.
    ///
    /// - Parameters:
    ///   - lastEncounterDate: The date of the cat's most recent encounter, if any.
    ///   - filterState: The current filter selections.
    /// - Returns: `true` if the pin should be shown.
    public static func shouldShowLocalPin(
        lastEncounterDate: Date?,
        filterState: MapFilterState
    ) -> Bool {
        // Owner filter: if owner filters are active but "my cats" is not selected, hide local pins
        if !filterState.ownerFilters.isEmpty && !filterState.ownerFilters.contains(.myCats) {
            return false
        }

        // Time range filter
        if let cutoff = filterState.timeRange.cutoffDate() {
            guard let encounterDate = lastEncounterDate, encounterDate >= cutoff else {
                return false
            }
        }

        return true
    }

    /// Determines whether a remote (friend's) encounter pin passes the current filters.
    ///
    /// - Parameters:
    ///   - encounterDate: The date of the remote encounter.
    ///   - ownerID: The owner ID of the remote encounter.
    ///   - followedUserIDs: Set of user IDs the current user follows.
    ///   - filterState: The current filter selections.
    /// - Returns: `true` if the pin should be shown.
    public static func shouldShowRemotePin(
        encounterDate: Date,
        ownerID: String,
        followedUserIDs: Set<String>,
        filterState: MapFilterState
    ) -> Bool {
        // Owner filter: if owner filters are active but "friends' cats" is not selected, hide remote pins
        if !filterState.ownerFilters.isEmpty && !filterState.ownerFilters.contains(.friendsCats) {
            return false
        }

        // If "friends' cats" is explicitly selected, verify the owner is actually followed
        if filterState.ownerFilters.contains(.friendsCats) && !followedUserIDs.contains(ownerID) {
            return false
        }

        // Time range filter
        if let cutoff = filterState.timeRange.cutoffDate() {
            guard encounterDate >= cutoff else {
                return false
            }
        }

        return true
    }
}
