import SwiftUI
import CatchCore

struct PendingRequestRowView: View {
    let follow: Follow
    let onApprove: () async throws -> Void
    let onDecline: () async throws -> Void

    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.title2)
                .foregroundStyle(CatchTheme.primary)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(follow.followerID)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                    .lineLimit(1)

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
    }
}
