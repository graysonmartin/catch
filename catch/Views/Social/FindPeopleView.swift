import SwiftUI
import CatchCore

struct FindPeopleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKFollowService.self) private var followService
    @Environment(AppleAuthService.self) private var authService

    @State private var searchText = ""
    @State private var results: [CloudUserProfile] = []
    @State private var isSearching = false
    @State private var sentFollowIDs: Set<String> = []
    @State private var rateLimitMessage: String?

    private var cloudKitService: CloudKitService = CKCloudKitService()

    private var currentUserID: String {
        authService.authState.user?.userIdentifier ?? ""
    }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty && !searchText.isEmpty && !isSearching {
                    ContentUnavailableView(
                        CatchStrings.Social.noOneFound,
                        systemImage: "person.slash",
                        description: Text(CatchStrings.Social.tryDifferentName)
                    )
                } else {
                    ForEach(results, id: \.recordName) { user in
                        resultRow(for: user)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if searchText.isEmpty && results.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: CatchStrings.Social.findYourPeople,
                        subtitle: CatchStrings.Social.findPeopleSubtitle
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let rateLimitMessage {
                    Text(rateLimitMessage)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CatchSpacing.space8)
                        .background(CatchTheme.cardBackground)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: rateLimitMessage)
            .searchable(text: $searchText, prompt: CatchStrings.Social.searchByNameOrUsername)
            .navigationTitle(CatchStrings.Social.findPeople)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CatchStrings.Common.done) { dismiss() }
                }
            }
            .task(id: searchText) {
                await search()
            }
        }
    }

    // MARK: - Row

    private func resultRow(for user: CloudUserProfile) -> some View {
        HStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(CatchTheme.secondary)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(user.displayName.isEmpty ? CatchStrings.Social.anonymous : user.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)

                if let username = user.username, !username.isEmpty {
                    Text(UsernameValidator.formatDisplay(username))
                        .font(.caption)
                        .foregroundStyle(CatchTheme.primary)
                }

                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            actionButton(for: user)
        }
    }

    @ViewBuilder
    private func actionButton(for user: CloudUserProfile) -> some View {
        let targetID = user.appleUserID

        if targetID == currentUserID {
            Text(CatchStrings.Social.you)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else if followService.isFollowing(targetID) {
            Text(CatchStrings.Social.followingStatus)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else if followService.pendingRequestTo(targetID) != nil || sentFollowIDs.contains(targetID) {
            Text(CatchStrings.Social.requestedStatus)
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else {
            Button {
                performFollow(targetID: targetID, isPrivate: user.isPrivate)
            } label: {
                Text(user.isPrivate ? CatchStrings.Social.request : CatchStrings.Social.follow)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, CatchSpacing.space12)
                    .padding(.vertical, CatchSpacing.space6)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            results = []
            return
        }

        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }

        isSearching = true
        defer { isSearching = false }

        results = (try? await cloudKitService.searchUsers(query: query)) ?? []
    }

    private func performFollow(targetID: String, isPrivate: Bool) {
        Task {
            do {
                try await followService.follow(
                    targetID: targetID,
                    by: currentUserID,
                    isTargetPrivate: isPrivate
                )
                if isPrivate {
                    sentFollowIDs.insert(targetID)
                }
                rateLimitMessage = nil
            } catch let error as FollowServiceError {
                if case .rateLimited = error {
                    showFollowRateLimitFeedback()
                }
            } catch {}
        }
    }

    private func showFollowRateLimitFeedback() {
        rateLimitMessage = CatchStrings.RateLimit.followCooldown
        Task {
            try? await Task.sleep(for: .seconds(3))
            rateLimitMessage = nil
        }
    }
}
