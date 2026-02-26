import SwiftUI

struct InteractionBar: View {
    let encounterRecordName: String
    @Binding var showComments: Bool

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?

    var body: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeButton
            commentButton
            Spacer()
        }
    }

    // MARK: - Subviews

    private var likeButton: some View {
        Button {
            guard let socialService else { return }
            Task {
                try? await socialService.toggleLike(encounterRecordName: encounterRecordName)
            }
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? CatchTheme.primary : CatchTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var commentButton: some View {
        Button {
            showComments = true
        } label: {
            HStack(spacing: CatchSpacing.space4) {
                Image(systemName: "bubble.right")
                    .foregroundStyle(CatchTheme.textSecondary)
                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var isLiked: Bool {
        socialService?.isLiked(encounterRecordName) ?? false
    }

    private var likeCount: Int {
        socialService?.likeCount(for: encounterRecordName) ?? 0
    }

    private var commentCount: Int {
        socialService?.commentCount(for: encounterRecordName) ?? 0
    }
}
