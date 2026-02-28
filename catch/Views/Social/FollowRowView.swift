import SwiftUI
import CatchCore

struct FollowRowView: View {
    let follow: Follow
    let currentUserID: String
    let isFollowerRow: Bool
    var resolvedName: String?
    let onAction: () async throws -> Void

    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @State private var isShowingConfirmation = false
    @State private var fetchedName: String?
    @State private var resolvedUsername: String?

    private var targetUserID: String {
        isFollowerRow ? follow.followerID : follow.followeeID
    }

    private var displayName: String {
        resolvedName ?? fetchedName ?? targetUserID
    }

    private var actionLabel: String {
        isFollowerRow ? CatchStrings.Social.removeFollower : CatchStrings.Social.unfollow
    }

    var body: some View {
        NavigationLink {
            RemoteProfileContent(
                userID: targetUserID,
                initialDisplayName: resolvedName
            )
        } label: {
            HStack(spacing: CatchSpacing.space12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CatchTheme.secondary)

                VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                    Text(displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(1)

                    if let username = resolvedUsername, !username.isEmpty {
                        Text(UsernameValidator.formatDisplay(username))
                            .font(.caption)
                            .foregroundStyle(CatchTheme.primary)
                    }

                    Text(CatchStrings.Social.since(follow.createdAt))
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
            Text(CatchStrings.Social.areYouSure)
        }
        .task {
            // Skip individual fetch if name was batch-resolved by parent
            guard resolvedName == nil else { return }
            let profile = await browseService?.fetchProfile(userID: targetUserID)
            fetchedName = profile?.displayName
            resolvedUsername = profile?.username
        }
    }
}
