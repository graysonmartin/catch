import SwiftUI
import CatchCore

struct InteractionBar: View {
    let encounterRecordName: String
    @Binding var showComments: Bool
    var ownerRoute: RemoteProfileRoute?

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeButton
            commentButton
            Spacer()
            if let ownerRoute {
                ownerLink(route: ownerRoute)
            }
        }
    }

    // MARK: - Subviews

    private var likeButton: some View {
        Button {
            guard let socialService else { return }
            Task {
                do {
                    try await socialService.toggleLike(encounterRecordName: encounterRecordName)
                } catch {
                    toastManager.showError(CatchStrings.Toast.likeFailed)
                }
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

    private func ownerLink(route: RemoteProfileRoute) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: CatchSpacing.space4) {
                Text(CatchStrings.Feed.spottedBy(route.displayName))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CatchTheme.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
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
