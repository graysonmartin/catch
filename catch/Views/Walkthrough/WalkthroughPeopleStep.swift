import SwiftUI
import CatchCore

/// Suggested people step of the new-user walkthrough.
/// Shows a list of active users the new user can follow right away.
struct WalkthroughPeopleStep: View {
    @Environment(SuggestedPeopleService.self) private var suggestedPeopleService
    @Environment(SupabaseFollowService.self) private var followService
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    var onComplete: () -> Void

    private var currentUserID: String {
        authService.authState.user?.id ?? ""
    }

    private var people: [SuggestedPerson] {
        suggestedPeopleService.suggestedPeople
    }

    var body: some View {
        VStack(spacing: CatchSpacing.space24) {
            headerSection
                .padding(.top, CatchSpacing.space24)

            contentSection

            Spacer()
        }
        .padding(.horizontal, CatchSpacing.space32)
        .task {
            await suggestedPeopleService.loadIfNeeded()
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(CatchTheme.primary)

            Text(CatchStrings.Walkthrough.peopleTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            Text(CatchStrings.Walkthrough.peopleSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        if suggestedPeopleService.isLoading {
            PawLoadingView(size: .inline, label: CatchStrings.Walkthrough.loadingPeople)
                .padding(.top, CatchSpacing.space20)
        } else if people.isEmpty {
            emptyState
        } else {
            peopleList
        }
    }

    private var emptyState: some View {
        Text(CatchStrings.Walkthrough.noPeopleYet)
            .font(.subheadline)
            .foregroundStyle(CatchTheme.textSecondary)
            .padding(.top, CatchSpacing.space20)
    }

    private var peopleList: some View {
        ScrollView {
            LazyVStack(spacing: CatchSpacing.space12) {
                ForEach(people) { person in
                    WalkthroughPersonRow(
                        person: person,
                        isFollowing: followService.isFollowing(person.id),
                        isPending: followService.pendingRequestTo(person.id) != nil,
                        onFollow: { performFollow(person: person) }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func performFollow(person: SuggestedPerson) {
        Task {
            do {
                try await followService.follow(
                    targetID: person.id,
                    by: currentUserID,
                    isTargetPrivate: false
                )
            } catch {
                toastManager.showError(CatchStrings.Toast.followFailed)
            }
        }
    }
}
