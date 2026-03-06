import SwiftUI
import CatchCore

struct FollowRowView: View {
    let follow: Follow
    let currentUserID: String
    let isFollowerRow: Bool
    let onAction: () async throws -> Void

    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @Environment(ToastManager.self) private var toastManager
    @State private var isShowingConfirmation = false
    @State private var resolvedName: String?
    @State private var resolvedUsername: String?

    private var targetUserID: String {
        isFollowerRow ? follow.followerID : follow.followeeID
    }

    private var hasResolvedName: Bool {
        resolvedName != nil
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
                    Text(resolvedName ?? CatchStrings.Social.loadingName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .lineLimit(1)
                        .redacted(reason: hasResolvedName ? [] : .placeholder)

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
                Task {
                    do {
                        try await onAction()
                    } catch {
                        let message = isFollowerRow
                            ? CatchStrings.Toast.removeFollowerFailed
                            : CatchStrings.Toast.unfollowFailed
                        toastManager.showError(message)
                    }
                }
            }
        } message: {
            Text(CatchStrings.Social.areYouSure)
        }
        .task {
            if let cached = browseService?.cachedDisplayName(for: targetUserID) {
                resolvedName = cached
            }

            let profile = await browseService?.fetchProfile(userID: targetUserID)
            resolvedName = profile?.displayName
            resolvedUsername = profile?.username
        }
    }
}
