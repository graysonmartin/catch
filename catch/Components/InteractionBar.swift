import SwiftUI
import CatchCore

struct InteractionBar: View {
    let encounterRecordName: String
    @Binding var showDetail: Bool
    var ownerRoute: RemoteProfileRoute?
    var ownerHandle: String?
    var isOwnEncounter: Bool = false
    var encounterDate: Date?

    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(ToastManager.self) private var toastManager

    @State private var showLikedBySheet = false

    private var formattedDate: String? {
        encounterDate.map { DateFormatting.encounterDate($0) }
    }

    var body: some View {
        HStack(spacing: CatchSpacing.space16) {
            likeSection
            commentButton
            Spacer()
            spottedLabel
        }
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
                    } catch is RateLimitError {
                        toastManager.showError(CatchStrings.Toast.rateLimitedLike)
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

    // MARK: - Spotted Label

    @ViewBuilder
    private var spottedLabel: some View {
        if let ownerRoute {
            NavigationLink(value: ownerRoute) {
                HStack(spacing: CatchSpacing.space4) {
                    spottedText(name: ownerHandle ?? ownerRoute.displayName, highlight: ownerHandle != nil)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            .lineLimit(1)
        } else if isOwnEncounter {
            spottedText(name: CatchStrings.Social.you, highlight: true)
                .lineLimit(1)
        } else if let formattedDate {
            Text(CatchStrings.Feed.spottedOn(formattedDate))
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private func spottedText(name: String, highlight: Bool) -> some View {
        Group {
            if let formattedDate {
                Text(CatchStrings.Feed.spottedOnByPrefix(formattedDate))
                    .foregroundStyle(CatchTheme.textSecondary) +
                Text(name)
                    .foregroundStyle(highlight ? CatchTheme.primary : CatchTheme.textSecondary)
            } else {
                Text(CatchStrings.Feed.spottedByPrefix)
                    .foregroundStyle(CatchTheme.textSecondary) +
                Text(name)
                    .foregroundStyle(highlight ? CatchTheme.primary : CatchTheme.textSecondary)
            }
        }
        .font(.caption.weight(.medium))
        .truncationMode(.tail)
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
