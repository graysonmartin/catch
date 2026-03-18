import SwiftUI
import CatchCore

private enum Layout {
    static let avatarSize: CGFloat = 40
    static let initialFontSize: CGFloat = 16
}

struct CommentRowView: View {
    let comment: EncounterComment
    let currentUserID: String?
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var isOwnComment: Bool {
        currentUserID != nil && comment.userID == currentUserID
    }

    private var isNavigable: Bool {
        !isOwnComment && !comment.isPending
    }

    var body: some View {
        HStack(alignment: .top, spacing: CatchSpacing.space10) {
            authorLink
            VStack(alignment: .leading, spacing: CatchSpacing.space4) {
                HStack(alignment: .center) {
                    authorNameLink
                    if comment.isPending {
                        Text(CatchStrings.Interaction.sending)
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.textSecondary)
                    } else {
                        Text(comment.createdAt.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }
                    Spacer()
                    if isOwnComment && !comment.isPending {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundStyle(CatchTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textPrimary)
            }
        }
        .padding(.vertical, CatchSpacing.space4)
        .opacity(comment.isPending ? 0.6 : 1.0)
        .alert(CatchStrings.Interaction.deleteComment, isPresented: $showDeleteConfirm) {
            Button(CatchStrings.Common.delete, role: .destructive) {
                onDelete()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(CatchStrings.Interaction.deleteCommentConfirm)
        }
    }

    // MARK: - Author Navigation

    @ViewBuilder
    private var authorLink: some View {
        if isNavigable {
            NavigationLink(value: profileRoute) {
                avatar
            }
            .buttonStyle(.plain)
        } else {
            avatar
        }
    }

    @ViewBuilder
    private var authorNameLink: some View {
        if isNavigable {
            NavigationLink(value: profileRoute) {
                Text(comment.authorName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)
            }
            .buttonStyle(.plain)
        } else {
            Text(comment.authorName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CatchTheme.textPrimary)
        }
    }

    private var profileRoute: RemoteProfileRoute {
        RemoteProfileRoute(
            userID: comment.userID,
            displayName: comment.authorName
        )
    }

    // MARK: - Avatar

    private var avatar: some View {
        Group {
            if let url = comment.avatarURL, !url.isEmpty {
                UserAvatarView(avatarURL: url, size: Layout.avatarSize)
            } else {
                initialAvatar
            }
        }
    }

    private var initialAvatar: some View {
        Circle()
            .fill(CatchTheme.secondary)
            .frame(width: Layout.avatarSize, height: Layout.avatarSize)
            .overlay {
                Text(String(comment.authorName.prefix(1)).uppercased())
                    .font(.system(size: Layout.initialFontSize, weight: .bold))
                    .foregroundStyle(CatchTheme.primary)
            }
    }
}
