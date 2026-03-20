import SwiftUI
import CatchCore

private enum Layout {
    static let avatarSize: CGFloat = 40
    static let thumbnailSize: CGFloat = 44
    static let unreadDotSize: CGFloat = 8
    static let initialFontSize: CGFloat = 16
}

struct NotificationRowView: View {
    let item: NotificationItem
    var onAvatarTap: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: CatchSpacing.space10) {
            avatarView
            contentColumn
            Spacer(minLength: 0)
            trailingContent
        }
        .padding(.vertical, CatchSpacing.space8)
        .padding(.horizontal, CatchSpacing.space16)
        .background(item.isRead ? Color.clear : CatchTheme.primary.opacity(0.05))
        .contentShape(Rectangle())
    }

    // MARK: - Avatar

    private var avatarView: some View {
        Button {
            onAvatarTap?()
        } label: {
            ZStack(alignment: .topLeading) {
                if let url = item.actorAvatarURL, !url.isEmpty {
                    UserAvatarView(avatarURL: url, size: Layout.avatarSize)
                } else {
                    initialAvatar
                }

                if !item.isRead {
                    Circle()
                        .fill(CatchTheme.primary)
                        .frame(width: Layout.unreadDotSize, height: Layout.unreadDotSize)
                        .offset(x: -2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(onAvatarTap == nil)
        .accessibilityLabel(CatchStrings.Accessibility.userAvatar(name: item.actorDisplayName))
    }

    private var initialAvatar: some View {
        Circle()
            .fill(CatchTheme.secondary)
            .frame(width: Layout.avatarSize, height: Layout.avatarSize)
            .overlay {
                Text(String(item.actorDisplayName.prefix(1)).uppercased())
                    .font(.system(size: Layout.initialFontSize, weight: .bold))
                    .foregroundStyle(CatchTheme.primary)
            }
    }

    // MARK: - Content

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space2) {
            (Text(item.actorDisplayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CatchTheme.textPrimary) +
            Text(" \(item.actionDescription)")
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary))
                .lineLimit(2)

            Text(item.timestamp.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    // MARK: - Trailing Thumbnail

    @ViewBuilder
    private var trailingContent: some View {
        if let url = item.encounterThumbnailURL, !url.isEmpty {
            RemoteImageView(urlString: url) {
                RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight)
                    .fill(CatchTheme.secondary.opacity(0.3))
                    .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            }
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadiusTight))
        }
    }
}
