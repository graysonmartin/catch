import SwiftUI
import CatchCore

struct InteractionBar: View {
    let encounterRecordName: String
    @Binding var showDetail: Bool
    var ownerRoute: RemoteProfileRoute?
    var isOwnEncounter: Bool = false

    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(ToastManager.self) private var toastManager

    @State private var showLikedBySheet = false

    var body: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeSection
            commentButton
            Spacer()
            if let ownerRoute {
                ownerLink(route: ownerRoute)
            } else if isOwnEncounter {
                spottedByYouLabel
            }
        }
        .frame(minHeight: CatchTheme.minTapTarget)
        .sheet(isPresented: $showLikedBySheet) {
            LikedByListView(encounterRecordName: encounterRecordName)
        }
    }

    // MARK: - Subviews

    private var likeSection: some View {
        HStack(spacing: CatchSpacing.space4) {
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
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? CatchTheme.primary : CatchTheme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLiked ? CatchStrings.Accessibility.unlikeButton : CatchStrings.Accessibility.likeButton)

            if likeCount > 0 {
                Button {
                    showLikedBySheet = true
                } label: {
                    Text("\(likeCount)")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(CatchStrings.Accessibility.likeCount(likeCount))
            }
        }
    }

    private var commentButton: some View {
        Button {
            showDetail = true
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
        .accessibilityLabel(CatchStrings.Accessibility.commentButton(commentCount))
    }

    private var spottedByYouLabel: some View {
        (Text(CatchStrings.Feed.spottedByPrefix)
            .foregroundStyle(CatchTheme.textSecondary) +
        Text(CatchStrings.Social.you)
            .foregroundStyle(CatchTheme.primary))
            .font(.caption.weight(.medium))
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
