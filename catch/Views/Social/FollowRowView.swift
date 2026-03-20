import SwiftUI
import CatchCore

struct FollowRowView: View {
    let follow: Follow
    let currentUserID: String
    let isFollowerRow: Bool
    let onAction: () async throws -> Void

    @Environment(SupabaseUserBrowseService.self) private var browseService: SupabaseUserBrowseService?
    @Environment(ToastManager.self) private var toastManager
    @State private var resolvedName: String?
    @State private var resolvedUsername: String?
    @State private var resolvedAvatarURL: String?

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
                UserAvatarView(avatarURL: resolvedAvatarURL, accessibilityName: resolvedName)

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
                            .lineLimit(1)
                    }
                }

                Spacer()

                Menu {
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
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .task {
            if let profile = browseService?.cachedProfile(for: targetUserID) {
                resolvedName = profile.displayName
                resolvedUsername = profile.username
                resolvedAvatarURL = profile.avatarURL
                return
            }

            let profile = await browseService?.fetchProfile(userID: targetUserID)
            resolvedName = profile?.displayName
            resolvedUsername = profile?.username
            resolvedAvatarURL = profile?.avatarURL
        }
    }
}
