import SwiftUI

struct FollowRowView: View {
    let follow: Follow
    let currentUserID: String
    let isFollowerRow: Bool
    let onAction: () async throws -> Void

    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @State private var isShowingConfirmation = false
    @State private var resolvedName: String?

    private var targetUserID: String {
        isFollowerRow ? follow.followerID : follow.followeeID
    }

    private var displayName: String {
        resolvedName ?? targetUserID
    }

    private var actionLabel: String {
        isFollowerRow ? "remove follower" : "unfollow"
    }

    var body: some View {
        NavigationLink {
            UserPublicProfileView(
                userID: targetUserID,
                initialDisplayName: resolvedName
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CatchTheme.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
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
        }
        .confirmationDialog(actionLabel, isPresented: $isShowingConfirmation) {
            Button(actionLabel, role: .destructive) {
                Task { try? await onAction() }
            }
        } message: {
            Text("are you sure?")
        }
        .task {
            resolvedName = await browseService?.fetchDisplayName(userID: targetUserID)
        }
    }
}
