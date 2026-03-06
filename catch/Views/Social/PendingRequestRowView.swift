import SwiftUI
import CatchCore

struct PendingRequestRowView: View {
    let follow: Follow
    let onApprove: () async throws -> Void
    let onDecline: () async throws -> Void

    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @Environment(ToastManager.self) private var toastManager
    @State private var resolvedName: String?

    private var hasResolvedName: Bool {
        resolvedName != nil
    }

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.title2)
                .foregroundStyle(CatchTheme.primary)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(resolvedName ?? CatchStrings.Social.loadingName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                    .lineLimit(1)
                    .redacted(reason: hasResolvedName ? [] : .placeholder)

                Text(CatchStrings.Social.wantsToFollowYou)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()

            Button {
                Task {
                    do {
                        try await onApprove()
                    } catch {
                        toastManager.showError(CatchStrings.Toast.approveFailed)
                    }
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(CatchTheme.primary)
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    do {
                        try await onDecline()
                    } catch {
                        toastManager.showError(CatchStrings.Toast.declineFailed)
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .task {
            if let cached = browseService?.cachedDisplayName(for: follow.followerID) {
                resolvedName = cached
                return
            }

            resolvedName = await browseService?.fetchDisplayName(userID: follow.followerID)
        }
    }
}
