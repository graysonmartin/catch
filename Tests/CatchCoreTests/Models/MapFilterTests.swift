import XCTest
@testable import CatchCore

final class MapFilterTests: XCTestCase {

    // MARK: - MapFilterState

    func testDefaultStateHasNoActiveFilters() {
        let state = MapFilterState()
        XCTAssertFalse(state.hasActiveFilters)
        XCTAssertTrue(state.ownerFilters.isEmpty)
        XCTAssertEqual(state.timeRange, .allTime)
    }

    func testOwnerFilterMakesStateActive() {
        let state = MapFilterState(ownerFilters: [.myCats])
        XCTAssertTrue(state.hasActiveFilters)
    }

    func testTimeRangeFilterMakesStateActive() {
        let state = MapFilterState(timeRange: .last7Days)
        XCTAssertTrue(state.hasActiveFilters)
    }

    func testToggleOwnerFilterAdds() {
        var state = MapFilterState()
        state.toggleOwnerFilter(.myCats)
        XCTAssertTrue(state.ownerFilters.contains(.myCats))
    }

    func testToggleOwnerFilterRemoves() {
        var state = MapFilterState(ownerFilters: [.myCats])
        state.toggleOwnerFilter(.myCats)
        XCTAssertFalse(state.ownerFilters.contains(.myCats))
    }

    func testResetClearsAll() {
        var state = MapFilterState(ownerFilters: [.myCats, .friendsCats], timeRange: .last7Days)
        state.reset()
        XCTAssertFalse(state.hasActiveFilters)
        XCTAssertTrue(state.ownerFilters.isEmpty)
        XCTAssertEqual(state.timeRange, .allTime)
    }

    // MARK: - MapTimeRange cutoff

    func testAllTimeReturnsNilCutoff() {
        XCTAssertNil(MapTimeRange.allTime.cutoffDate())
    }

    func testLast7DaysReturnsCutoffInPast() {
        let cutoff = MapTimeRange.last7Days.cutoffDate()
        XCTAssertNotNil(cutoff)
        // Should be approximately 7 days ago
        let daysAgo = Calendar.current.dateComponents([.day], from: cutoff!, to: Date()).day!
        XCTAssertEqual(daysAgo, 7)
    }

    func testLast30DaysReturnsCutoffInPast() {
        let cutoff = MapTimeRange.last30Days.cutoffDate()
        XCTAssertNotNil(cutoff)
        let daysAgo = Calendar.current.dateComponents([.day], from: cutoff!, to: Date()).day!
        XCTAssertEqual(daysAgo, 30)
    }

    func testCutoffDateUsesProvidedNow() {
        let fixedNow = Date(timeIntervalSince1970: 1_000_000)
        let cutoff = MapTimeRange.last7Days.cutoffDate(from: fixedNow)
        XCTAssertNotNil(cutoff)
        XCTAssertTrue(cutoff! < fixedNow)
    }
}
