import SwiftUI

enum SocialTab: String, CaseIterable, Identifiable {
    case followers
    case following

    var id: String { rawValue }
}

struct SocialView: View {
    @Environment(CKFollowService.self) private var followService
    @Environment(AppleAuthService.self) private var authService
    @State private var isShowingFindPeople = false
    @State var selectedTab: SocialTab

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(SocialTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

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
        .navigationTitle(selectedTab.rawValue)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingFindPeople = true
                } label: {
                    Label("find people", systemImage: "magnifyingglass")
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
        Section("requests") {
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
        Section("followers") {
            ForEach(followService.followers) { follow in
                FollowRowView(
                    follow: follow,
                    currentUserID: currentUserID,
                    isFollowerRow: true,
                    onAction: { try await followService.removeFollower(follow) }
                )
            }
        }
    }

    private var followingSection: some View {
        Section("following") {
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
                    title: "no followers yet",
                    subtitle: "your adoring public hasn't arrived"
                )
            case .following:
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "not following anyone",
                    subtitle: "find some people to follow and start building your circle"
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
    }
}
