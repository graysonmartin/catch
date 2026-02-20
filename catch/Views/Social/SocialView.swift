import SwiftUI

struct SocialView: View {
    @Environment(CKFollowService.self) private var followService
    @Environment(AppleAuthService.self) private var authService
    @State private var isShowingFindPeople = false

    var body: some View {
        List {
            if !followService.pendingRequests.isEmpty {
                requestsSection
            }
            if !followService.followers.isEmpty {
                followersSection
            }
            if !followService.following.isEmpty {
                followingSection
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "no one here yet",
                    subtitle: "find some people to follow and start building your circle"
                )
            }
        }
        .navigationTitle("social")
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

    // MARK: - Helpers

    private var isEmpty: Bool {
        followService.pendingRequests.isEmpty
            && followService.followers.isEmpty
            && followService.following.isEmpty
    }

    private var currentUserID: String {
        authService.authState.user?.userIdentifier ?? ""
    }

    private func refresh() async {
        guard let userID = authService.authState.user?.userIdentifier else { return }
        try? await followService.refresh(for: userID)
    }
}
