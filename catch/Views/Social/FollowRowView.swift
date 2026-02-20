import SwiftUI

struct FollowRowView: View {
    let follow: Follow
    let currentUserID: String
    let isFollowerRow: Bool
    let onAction: () async throws -> Void

    @State private var isShowingConfirmation = false

    private var displayID: String {
        isFollowerRow ? follow.followerID : follow.followeeID
    }

    private var actionLabel: String {
        isFollowerRow ? "remove follower" : "unfollow"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(CatchTheme.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayID)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                    .lineLimit(1)

                Text("since \(follow.createdAt.formatted(.dateTime.month(.abbreviated).year()))")
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }

            Spacer()

            Menu {
                Button(actionLabel, role: .destructive) {
                    isShowingConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
        .confirmationDialog(actionLabel, isPresented: $isShowingConfirmation) {
            Button(actionLabel, role: .destructive) {
                Task { try? await onAction() }
            }
        } message: {
            Text("are you sure?")
        }
    }
}
