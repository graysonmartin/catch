import SwiftUI
import CatchCore

private enum CardLayout {
    static let cardWidth: CGFloat = 150
    static let avatarSize: CGFloat = 44
}

struct SuggestedPersonCard: View {
    let person: SuggestedPerson
    let isFollowing: Bool
    let isPending: Bool
    let onFollow: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: CatchSpacing.space8) {
                avatar
                nameSection
                catCountLabel
                actionButton
            }
            .padding(CatchSpacing.space12)
            .frame(width: CardLayout.cardWidth)
            .background(CatchTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
            .shadow(
                color: .black.opacity(CatchTheme.cardShadowOpacity),
                radius: CatchTheme.cardShadowRadius,
                y: CatchTheme.cardShadowY
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var avatar: some View {
        UserAvatarView(avatarURL: person.avatarURL, size: CardLayout.avatarSize)
    }

    private var nameSection: some View {
        VStack(spacing: CatchSpacing.space2) {
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
        }
    }

    private var catCountLabel: some View {
        Text(CatchStrings.Feed.catCount(person.catCount))
            .font(.caption2)
            .foregroundStyle(CatchTheme.textSecondary)
    }

    @ViewBuilder
    private var actionButton: some View {
        if isFollowing {
            Text(CatchStrings.Social.followingStatus)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else if isPending {
            Text(CatchStrings.Social.requestedStatus)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else {
            Button {
                onFollow()
            } label: {
                Text(person.isPrivate ? CatchStrings.Social.request : CatchStrings.Social.follow)
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
}
