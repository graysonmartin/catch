import SwiftUI
import CatchCore

/// A single row in the walkthrough's suggested people list.
struct WalkthroughPersonRow: View {
    let person: SuggestedPerson
    let isFollowing: Bool
    let isPending: Bool
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            avatar
            nameSection
            Spacer()
            actionButton
        }
        .padding(CatchSpacing.space12)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusSmall))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    // MARK: - Subviews

    private var avatar: some View {
        UserAvatarView(avatarURL: person.avatarURL, size: 40)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
            Text(person.displayName.isEmpty ? CatchStrings.Social.anonymous : person.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.textPrimary)
                .lineLimit(1)

            if let username = person.username {
                Text(UsernameValidator.formatDisplay(username))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.primary)
                    .lineLimit(1)
            }

            Text(CatchStrings.Feed.catCount(person.catCount))
                .font(.caption2)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isFollowing {
            followStateLabel(CatchStrings.Social.followingStatus)
        } else if isPending {
            followStateLabel(CatchStrings.Social.requestedStatus)
        } else {
            Button {
                onFollow()
            } label: {
                Text(CatchStrings.Social.follow)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, CatchSpacing.space12)
                    .padding(.vertical, CatchSpacing.space6)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func followStateLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(CatchTheme.textSecondary)
    }
}
