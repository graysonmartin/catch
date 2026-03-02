import SwiftUI
import CatchCore

struct InteractionBar: View {
    let encounterRecordName: String
    @Binding var showComments: Bool
    var ownerRoute: RemoteProfileRoute?

    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?
    @State private var rateLimitMessage: String?
    @State private var isLikeDisabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: CatchSpacing.space4) {
            HStack(spacing: CatchSpacing.space16) {
                likeButton
                commentButton
                Spacer()
                if let ownerRoute {
                    ownerLink(route: ownerRoute)
                }
            }

            if let rateLimitMessage {
                Text(rateLimitMessage)
                    .font(.caption2)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: rateLimitMessage)
    }

    // MARK: - Subviews

    private var likeButton: some View {
        Button {
            guard let socialService else { return }
            guard !isLikeDisabled else { return }
            Task {
                do {
                    try await socialService.toggleLike(encounterRecordName: encounterRecordName)
                    dismissRateLimitMessage()
                } catch let error as SocialInteractionError {
                    if case .rateLimited = error {
                        showRateLimitFeedback(CatchStrings.RateLimit.likeCooldown)
                    }
                } catch {}
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
        .opacity(isLikeDisabled ? 0.5 : 1.0)
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

    private func showRateLimitFeedback(_ message: String) {
        rateLimitMessage = message
        isLikeDisabled = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            dismissRateLimitMessage()
        }
    }

    private func dismissRateLimitMessage() {
        rateLimitMessage = nil
        isLikeDisabled = false
    }
}
