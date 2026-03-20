import SwiftUI
import CatchCore

struct SuggestedPeopleSection: View {
    @Environment(SuggestedPeopleService.self) private var suggestedPeopleService
    @Environment(SupabaseFollowService.self) private var followService
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager

    private var currentUserID: String {
        authService.authState.user?.id ?? ""
    }

    var body: some View {
        let people = suggestedPeopleService.allFetchedPeople
        if !people.isEmpty {
            VStack(alignment: .leading, spacing: CatchSpacing.space12) {
                header
                cardRow(people: people)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Text(CatchStrings.Feed.suggestedHeader)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)

            Spacer()
        }
    }

    private func cardRow(people: [SuggestedPerson]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: CatchSpacing.space12) {
                ForEach(people) { person in
                    NavigationLink(value: RemoteProfileRoute(
                        userID: person.id,
                        displayName: person.displayName
                    )) {
                        SuggestedPersonCard(
                            person: person,
                            isFollowing: followService.isFollowing(person.id),
                            isPending: followService.pendingRequestTo(person.id) != nil,
                            onFollow: { performFollow(person: person) },
                            onTap: {}
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1) // Prevent shadow clipping
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
                // Card stays visible — shows "following" state
            } catch {
                toastManager.showError(CatchStrings.Toast.followFailed)
            }
        }
    }
}
