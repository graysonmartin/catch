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
    @Environment(AppleAuthService.self) private var authService
    @State private var isShowingFindPeople = false
    @State private var resolvedNames: [String: String] = [:]
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingFindPeople = true
                } label: {
                    Label(CatchStrings.Social.findPeople, systemImage: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $isShowingFindPeople) {
            FindPeopleView()
        }
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
                    displayName: resolvedNames[follow.followerID],
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
                    resolvedName: resolvedNames[follow.followerID],
                    onAction: { try await followService.removeFollower(follow) }
                )
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
                    resolvedName: resolvedNames[follow.followeeID],
                    onAction: {
                        try await followService.unfollow(
                            targetID: follow.followeeID,
                            by: currentUserID
                        )
                    }
                )
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
        authService.authState.user?.userIdentifier ?? ""
    }

    private func refresh() async {
        guard let userID = authService.authState.user?.userIdentifier else { return }
        try? await followService.refresh(for: userID)
        await resolveDisplayNames()
    }

    private func resolveDisplayNames() async {
        guard let browseService else { return }
        var userIDs: Set<String> = []
        for follow in followService.followers {
            userIDs.insert(follow.followerID)
        }
        for follow in followService.following {
            userIDs.insert(follow.followeeID)
        }
        for follow in followService.pendingRequests {
            userIDs.insert(follow.followerID)
        }
        guard !userIDs.isEmpty else { return }
        let names = await browseService.fetchDisplayNames(userIDs: Array(userIDs))
        resolvedNames = names
    }
}
