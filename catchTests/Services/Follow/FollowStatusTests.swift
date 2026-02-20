import Testing

@MainActor
struct FollowStatusTests {

    @Test func allCases_containsActiveAndPending() {
        let cases = FollowStatus.allCases
        #expect(cases.count == 2)
        #expect(cases.contains(.active))
        #expect(cases.contains(.pending))
    }

    @Test func rawValues_matchExpectedStrings() {
        #expect(FollowStatus.active.rawValue == "active")
        #expect(FollowStatus.pending.rawValue == "pending")
    }

    @Test func initFromRawValue_roundTrips() {
        #expect(FollowStatus(rawValue: "active") == .active)
        #expect(FollowStatus(rawValue: "pending") == .pending)
        #expect(FollowStatus(rawValue: "bogus") == nil)
    }
}
