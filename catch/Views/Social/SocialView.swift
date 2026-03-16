import SwiftUI
import CatchCore

enum SocialTab: String, CaseIterable, Identifiable {
    case followers
    case following

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .followers: CatchStrings.Social.followersTab
        case .following: CatchStrings.Social.followingTab
        }
    }
}

struct SocialView: View {
    @Environment(CKFollowService.self) private var followService
    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ToastManager.self) private var toastManager
    @State private var isLoadingMoreFollowers = false
    @State private var isLoadingMoreFollowing = false
    @State private var isResolvingNames = false
    @State var selectedTab: SocialTab

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(SocialTab.allCases) { tab in
                    Text(tab.displayName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, CatchSpacing.space8)

            List {
                switch selectedTab {
                case .followers:
                    followersContent
                case .following:
                    followingContent
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if isCurrentTabEmpty {
                    emptyState
                }
            }
        }
        .background(CatchTheme.background)
        .navigationTitle(selectedTab.displayName)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await refresh()
        }
        .task {
            await refresh()
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var followersContent: some View {
        if !followService.pendingRequests.isEmpty {
            requestsSection
        }
        if !followService.followers.isEmpty {
            followersSection
        }
    }

    @ViewBuilder
    private var followingContent: some View {
        if !followService.following.isEmpty {
            followingSection
        }
    }

    // MARK: - Sections

    private var requestsSection: some View {
        Section(CatchStrings.Social.requests) {
            ForEach(followService.pendingRequests) { follow in
                PendingRequestRowView(
                    follow: follow,
                    onApprove: { try await followService.approveRequest(follow) },
                    onDecline: { try await followService.declineRequest(follow) }
                )
            }
        }
    }

    private var followersSection: some View {
        Section(CatchStrings.Social.followersTab) {
            ForEach(followService.followers) { follow in
                FollowRowView(
                    follow: follow,
                    currentUserID: currentUserID,
                    isFollowerRow: true,
                    onAction: { try await followService.removeFollower(follow) }
                )
            }

            if followService.hasMoreFollowers {
                loadMoreFollowersRow
            }
        }
    }

    private var followingSection: some View {
        Section(CatchStrings.Social.followingTab) {
            ForEach(followService.following) { follow in
                FollowRowView(
                    follow: follow,
                    currentUserID: currentUserID,
                    isFollowerRow: false,
                    onAction: {
                        try await followService.unfollow(
                            targetID: follow.followeeID,
                            by: currentUserID
                        )
                    }
                )
            }

            if followService.hasMoreFollowing {
                loadMoreFollowingRow
            }
        }
    }

    // MARK: - Load More

    @ViewBuilder
    private var loadMoreFollowersRow: some View {
        if isLoadingMoreFollowers {
            HStack {
                Spacer()
                PawLoadingView(size: .inline)
                Spacer()
            }
            .listRowBackground(Color.clear)
        } else {
            Color.clear
                .frame(height: 1)
                .listRowBackground(Color.clear)
                .onAppear {
                    Task { await loadMoreFollowers() }
                }
        }
    }

    @ViewBuilder
    private var loadMoreFollowingRow: some View {
        if isLoadingMoreFollowing {
            HStack {
                Spacer()
                PawLoadingView(size: .inline)
                Spacer()
            }
            .listRowBackground(Color.clear)
        } else {
            Color.clear
                .frame(height: 1)
                .listRowBackground(Color.clear)
                .onAppear {
                    Task { await loadMoreFollowing() }
                }
        }
    }

    // MARK: - Empty States

    private var isCurrentTabEmpty: Bool {
        switch selectedTab {
        case .followers:
            return followService.pendingRequests.isEmpty && followService.followers.isEmpty
        case .following:
            return followService.following.isEmpty
        }
    }

    private var emptyState: some View {
        Group {
            switch selectedTab {
            case .followers:
                EmptyStateView(
                    icon: "person.2.slash",
                    title: CatchStrings.Social.noFollowersTitle,
                    subtitle: CatchStrings.Social.noFollowersSubtitle
                )
            case .following:
                EmptyStateView(
                    icon: "person.2.slash",
                    title: CatchStrings.Social.notFollowingTitle,
                    subtitle: CatchStrings.Social.notFollowingSubtitle
                )
            }
        }
    }

    // MARK: - Helpers

    private var currentUserID: String {
        authService.authState.user?.id ?? ""
    }

    private func refresh() async {
        guard let userID = authService.authState.user?.id else { return }
        do {
            try await followService.refresh(for: userID)
            await batchResolveDisplayNames()
        } catch {
            toastManager.showError(CatchStrings.Toast.syncFailed)
        }
    }

    private func batchResolveDisplayNames() async {
        guard let browseService else { return }
        isResolvingNames = true
        defer { isResolvingNames = false }

        var allUserIDs: [String] = []
        allUserIDs.append(contentsOf: followService.followers.map(\.followerID))
        allUserIDs.append(contentsOf: followService.following.map(\.followeeID))
        allUserIDs.append(contentsOf: followService.pendingRequests.map(\.followerID))

        let uniqueIDs = Array(Set(allUserIDs))
        guard !uniqueIDs.isEmpty else { return }

        _ = await browseService.batchFetchDisplayNames(userIDs: uniqueIDs)
    }

    private func loadMoreFollowers() async {
        guard !isLoadingMoreFollowers else { return }
        isLoadingMoreFollowers = true
        defer { isLoadingMoreFollowers = false }
        do {
            try await followService.loadMoreFollowers(for: currentUserID)
        } catch {
            toastManager.showError(CatchStrings.Toast.syncFailed)
        }
    }

    private func loadMoreFollowing() async {
        guard !isLoadingMoreFollowing else { return }
        isLoadingMoreFollowing = true
        defer { isLoadingMoreFollowing = false }
        do {
            try await followService.loadMoreFollowing(for: currentUserID)
        } catch {
            toastManager.showError(CatchStrings.Toast.syncFailed)
        }
    }
}
