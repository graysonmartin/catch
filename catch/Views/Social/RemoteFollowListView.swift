import SwiftUI
import CatchCore

struct RemoteFollowListView: View {
    let userID: String
    let displayName: String?
    let tab: RemoteFollowTab

    @Environment(CKFollowService.self) private var followService
    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @Environment(ToastManager.self) private var toastManager

    @State private var follows: [Follow] = []
    @State private var isLoading = true
    @State private var resolvedProfiles: [String: CloudUserProfile] = [:]

    var body: some View {
        Group {
            if isLoading {
                PawLoadingView()
            } else if follows.isEmpty {
                emptyState
            } else {
                List(follows, id: \.id) { follow in
                    let targetID = tab == .followers ? follow.followerID : follow.followeeID
                    NavigationLink {
                        RemoteProfileContent(
                            userID: targetID,
                            initialDisplayName: resolvedProfiles[targetID]?.displayName
                        )
                    } label: {
                        RemoteFollowRow(
                            targetUserID: targetID,
                            profile: resolvedProfiles[targetID],
                            since: follow.createdAt
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(CatchTheme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadFollows()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "person.2.slash",
            title: tab == .followers
                ? CatchStrings.Social.noFollowersTitle
                : CatchStrings.Social.notFollowingTitle,
            subtitle: tab == .followers
                ? CatchStrings.Social.remoteNoFollowers
                : CatchStrings.Social.remoteNotFollowing
        )
    }

    // MARK: - Helpers

    private var title: String {
        tab == .followers
            ? CatchStrings.Social.followersTab
            : CatchStrings.Social.followingTab
    }

    private func loadFollows() async {
        isLoading = true
        defer { isLoading = false }

        do {
            follows = tab == .followers
                ? try await followService.fetchFollowers(for: userID)
                : try await followService.fetchFollowing(for: userID)

            await resolveProfiles()
        } catch {
            toastManager.showError(CatchStrings.Toast.syncFailed)
        }
    }

    private func resolveProfiles() async {
        guard let browseService else { return }
        for follow in follows {
            let targetID = tab == .followers ? follow.followerID : follow.followeeID
            if let profile = await browseService.fetchProfile(userID: targetID) {
                resolvedProfiles[targetID] = profile
            }
        }
    }
}

// MARK: - Supporting Types

enum RemoteFollowTab {
    case followers
    case following
}

private struct RemoteFollowRow: View {
    let targetUserID: String
    let profile: CloudUserProfile?
    let since: Date

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(CatchTheme.secondary)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(profile?.displayName ?? targetUserID)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                    .lineLimit(1)

                if let username = profile?.username, !username.isEmpty {
                    Text(UsernameValidator.formatDisplay(username))
                        .font(.caption)
                        .foregroundStyle(CatchTheme.primary)
                }

                Text(CatchStrings.Social.since(since))
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }
}
