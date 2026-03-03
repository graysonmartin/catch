import SwiftUI
import CatchCore

private enum Layout {
    static let avatarSize: CGFloat = 32
    static let avatarFontSize: CGFloat = 14
}

struct CommentRowView: View {
    let comment: EncounterComment
    let currentUserID: String?
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var isOwnComment: Bool {
        currentUserID != nil && comment.userID == currentUserID
    }

    var body: some View {
        HStack(alignment: .top, spacing: CatchSpacing.space8) {
            avatar
            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                HStack {
                    Text(comment.userID.prefix(8))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
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

    private var avatar: some View {
        Circle()
            .fill(CatchTheme.secondary)
            .frame(width: Layout.avatarSize, height: Layout.avatarSize)
            .overlay {
                Text(String(comment.userID.prefix(1)).uppercased())
                    .font(.system(size: Layout.avatarFontSize, weight: .bold))
                    .foregroundStyle(CatchTheme.primary)
            }
    }
}
