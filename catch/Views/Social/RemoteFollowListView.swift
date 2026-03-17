import SwiftUI
import CatchCore

struct RemoteFollowListView: View {
    let userID: String
    let displayName: String?
    let tab: RemoteFollowTab

    @Environment(SupabaseFollowService.self) private var followService
    @Environment(SupabaseUserBrowseService.self) private var browseService: SupabaseUserBrowseService?
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
                            isResolved: resolvedProfiles[targetID] != nil
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

            await batchResolveProfiles()
        } catch {
            toastManager.showError(CatchStrings.Toast.syncFailed)
        }
    }

    private func batchResolveProfiles() async {
        guard let browseService else { return }

        let targetIDs = follows.map { follow in
            tab == .followers ? follow.followerID : follow.followeeID
        }
        guard !targetIDs.isEmpty else { return }

        _ = await browseService.batchFetchDisplayNames(userIDs: targetIDs)

        await withTaskGroup(of: (String, CloudUserProfile?).self) { group in
            for targetID in targetIDs {
                group.addTask {
                    let profile = await browseService.fetchProfile(userID: targetID)
                    return (targetID, profile)
                }
            }

            for await (targetID, profile) in group {
                if let profile {
                    resolvedProfiles[targetID] = profile
                }
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
    let isResolved: Bool

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            Group {
                if let avatarUrl = profile?.avatarURL, !avatarUrl.isEmpty {
                    RemoteImageView(urlString: avatarUrl) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(CatchTheme.secondary)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(CatchTheme.secondary)
                }
            }

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(profile?.displayName ?? CatchStrings.Social.loadingName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                    .lineLimit(1)
                    .redacted(reason: isResolved ? [] : .placeholder)

                if let username = profile?.username, !username.isEmpty {
                    Text(UsernameValidator.formatDisplay(username))
                        .font(.caption)
                        .foregroundStyle(CatchTheme.primary)
                        .lineLimit(1)
                }
            }
        }
    }
}
