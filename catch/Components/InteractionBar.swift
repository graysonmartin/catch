import SwiftUI
import CatchCore

private enum Layout {
    static let avatarPreviewSize: CGFloat = 18
    static let avatarOverlap: CGFloat = 6
}

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
        .sheet(isPresented: $showLikedBySheet) {
            LikedByListView(encounterRecordName: encounterRecordName)
        }
        .task(id: likeCount) {
            guard likeCount > 0 else { return }
            await socialService?.loadLikerAvatarPreview(for: encounterRecordName)
        }
    }

    // MARK: - Subviews

    private var likeSection: some View {
        HStack(spacing: CatchSpacing.space6) {
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

            if likeCount > 0 {
                Button {
                    showLikedBySheet = true
                } label: {
                    likePreviewLabel
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var likePreviewLabel: some View {
        HStack(spacing: CatchSpacing.space4) {
            let avatars = likerAvatars
            if !avatars.isEmpty {
                avatarStack(urls: avatars)
            }
            Text("\(likeCount)")
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    private func avatarStack(urls: [String]) -> some View {
        HStack(spacing: -Layout.avatarOverlap) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                UserAvatarView(avatarURL: url, size: Layout.avatarPreviewSize)
                    .overlay(
                        Circle()
                            .stroke(CatchTheme.background, lineWidth: 1.5)
                    )
                    .zIndex(Double(urls.count - index))
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

    private var likerAvatars: [String] {
        socialService?.likerAvatars(for: encounterRecordName) ?? []
    }
}
