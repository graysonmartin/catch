import Testing

@MainActor
struct FollowServiceErrorTests {

    @Test func allCases_haveNonNilErrorDescriptions() {
        let cases: [FollowServiceError] = [
            .notSignedIn,
            .cannotFollowSelf,
            .alreadyFollowing,
            .requestAlreadyPending,
            .followNotFound,
            .unauthorized
        ]
        for error in cases {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test func equatable_matchesSameCase() {
        #expect(FollowServiceError.notSignedIn == .notSignedIn)
        #expect(FollowServiceError.cannotFollowSelf == .cannotFollowSelf)
        #expect(FollowServiceError.alreadyFollowing == .alreadyFollowing)
        #expect(FollowServiceError.requestAlreadyPending == .requestAlreadyPending)
        #expect(FollowServiceError.followNotFound == .followNotFound)
        #expect(FollowServiceError.unauthorized == .unauthorized)
    }

    @Test func equatable_differsBetweenCases() {
        #expect(FollowServiceError.notSignedIn != .cannotFollowSelf)
        #expect(FollowServiceError.alreadyFollowing != .requestAlreadyPending)
    }
}
