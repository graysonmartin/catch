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
    @State private var resolvedAvatars: [String: UIImage] = [:]

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
                            avatarImage: resolvedAvatars[targetID],
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
            await prefetchAvatars()
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

        resolvedProfiles = await browseService.batchFetchProfiles(userIDs: targetIDs)
    }

    private func prefetchAvatars() async {
        await withTaskGroup(of: (String, UIImage?).self) { group in
            for (userID, profile) in resolvedProfiles {
                guard let urlString = profile.avatarURL, !urlString.isEmpty else { continue }
                group.addTask {
                    if let cached = RemoteImageCache.shared.image(for: urlString) {
                        return (userID, cached)
                    }
                    guard let url = URL(string: urlString),
                          let (data, _) = try? await URLSession.shared.data(from: url),
                          let image = UIImage(data: data) else {
                        return (userID, nil)
                    }
                    RemoteImageCache.shared.setImage(image, for: urlString)
                    return (userID, image)
                }
            }

            for await (userID, image) in group {
                if let image {
                    resolvedAvatars[userID] = image
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
    let avatarImage: UIImage?
    let isResolved: Bool

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                UserAvatarView(avatarURL: profile?.avatarURL)
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
