import Foundation

/// Determines whether the new-user walkthrough should be shown.
/// Pure logic — no SwiftUI dependencies. The app layer provides the storage.
public struct WalkthroughStateManager: Sendable {

    public init() {}

    /// Returns `true` if the walkthrough should be displayed.
    ///
    /// The walkthrough shows when ALL of these are true:
    /// - The user has completed onboarding (intro screens)
    /// - The user is signed in
    /// - The user has completed profile setup
    /// - The user has NOT yet completed the walkthrough
    public func shouldShowWalkthrough(
        hasCompletedOnboarding: Bool,
        isSignedIn: Bool,
        hasCompletedProfileSetup: Bool,
        hasCompletedWalkthrough: Bool
    ) -> Bool {
        hasCompletedOnboarding
            && isSignedIn
            && hasCompletedProfileSetup
            && !hasCompletedWalkthrough
    }

    /// Returns `true` if the walkthrough should be marked as completed
    /// because this is a returning user (profile already existed on the server).
    public func shouldSkipWalkthroughForReturningUser(profileExists: Bool) -> Bool {
        profileExists
    }

    /// Returns the walkthrough completion flag value after profile setup.
    /// New users get `false` (show walkthrough); returning users get `true` (skip it).
    public func walkthroughCompletionAfterProfileSetup(isNewUser: Bool) -> Bool {
        !isNewUser
    }
}
