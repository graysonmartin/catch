import XCTest
@testable import CatchCore

final class MapFilterServiceTests: XCTestCase {

    // MARK: - Local pin tests

    func testLocalPinShownByDefault() {
        let state = MapFilterState()
        XCTAssertTrue(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: Date(), filterState: state)
        )
    }

    func testLocalPinShownWhenMyCatsSelected() {
        let state = MapFilterState(ownerFilters: [.myCats])
        XCTAssertTrue(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: Date(), filterState: state)
        )
    }

    func testLocalPinHiddenWhenOnlyFriendsCatsSelected() {
        let state = MapFilterState(ownerFilters: [.friendsCats])
        XCTAssertFalse(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: Date(), filterState: state)
        )
    }

    func testLocalPinShownWhenBothOwnerFiltersSelected() {
        let state = MapFilterState(ownerFilters: [.myCats, .friendsCats])
        XCTAssertTrue(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: Date(), filterState: state)
        )
    }

    func testLocalPinHiddenWhenEncounterOutsideTimeRange() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        let state = MapFilterState(timeRange: .last7Days)
        XCTAssertFalse(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: oldDate, filterState: state)
        )
    }

    func testLocalPinShownWhenEncounterWithinTimeRange() {
        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        let state = MapFilterState(timeRange: .last7Days)
        XCTAssertTrue(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: recentDate, filterState: state)
        )
    }

    func testLocalPinHiddenWhenNoEncounterDateAndTimeRangeActive() {
        let state = MapFilterState(timeRange: .last30Days)
        XCTAssertFalse(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: nil, filterState: state)
        )
    }

    func testLocalPinShownWhenAllTimeSelected() {
        let oldDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())
        let state = MapFilterState(timeRange: .allTime)
        XCTAssertTrue(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: oldDate, filterState: state)
        )
    }

    // MARK: - Remote pin tests

    func testRemotePinHiddenByDefault() {
        let state = MapFilterState()
        XCTAssertFalse(
            MapFilterService.shouldShowRemotePin(
                encounterDate: Date(),
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testRemotePinShownWhenNoOwnerFiltersActive() {
        let state = MapFilterState(ownerFilters: [])
        XCTAssertTrue(
            MapFilterService.shouldShowRemotePin(
                encounterDate: Date(),
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testRemotePinHiddenWhenOnlyMyCatsSelected() {
        let state = MapFilterState(ownerFilters: [.myCats])
        XCTAssertFalse(
            MapFilterService.shouldShowRemotePin(
                encounterDate: Date(),
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testRemotePinShownWhenFriendsCatsSelected() {
        let state = MapFilterState(ownerFilters: [.friendsCats])
        XCTAssertTrue(
            MapFilterService.shouldShowRemotePin(
                encounterDate: Date(),
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testRemotePinHiddenWhenFriendsCatsSelectedButNotFollowed() {
        let state = MapFilterState(ownerFilters: [.friendsCats])
        XCTAssertFalse(
            MapFilterService.shouldShowRemotePin(
                encounterDate: Date(),
                ownerID: "user-1",
                followedUserIDs: ["user-2"],
                filterState: state
            )
        )
    }

    func testRemotePinShownWhenBothOwnerFiltersSelected() {
        let state = MapFilterState(ownerFilters: [.myCats, .friendsCats])
        XCTAssertTrue(
            MapFilterService.shouldShowRemotePin(
                encounterDate: Date(),
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testRemotePinHiddenWhenEncounterOutsideTimeRange() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())!
        let state = MapFilterState(ownerFilters: [.friendsCats], timeRange: .last7Days)
        XCTAssertFalse(
            MapFilterService.shouldShowRemotePin(
                encounterDate: oldDate,
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testRemotePinShownWhenEncounterWithinTimeRange() {
        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let state = MapFilterState(ownerFilters: [.friendsCats], timeRange: .last7Days)
        XCTAssertTrue(
            MapFilterService.shouldShowRemotePin(
                encounterDate: recentDate,
                ownerID: "user-1",
                followedUserIDs: ["user-1"],
                filterState: state
            )
        )
    }

    func testCombinedFilterFriendsCatsLast7Days() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let recentDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let state = MapFilterState(ownerFilters: [.friendsCats], timeRange: .last7Days)

        // Old encounter fails
        XCTAssertFalse(
            MapFilterService.shouldShowRemotePin(
                encounterDate: oldDate,
                ownerID: "friend-1",
                followedUserIDs: ["friend-1"],
                filterState: state
            )
        )

        // Recent encounter passes
        XCTAssertTrue(
            MapFilterService.shouldShowRemotePin(
                encounterDate: recentDate,
                ownerID: "friend-1",
                followedUserIDs: ["friend-1"],
                filterState: state
            )
        )

        // Local pin hidden when only friends selected
        XCTAssertFalse(
            MapFilterService.shouldShowLocalPin(lastEncounterDate: recentDate, filterState: state)
        )
    }
}
