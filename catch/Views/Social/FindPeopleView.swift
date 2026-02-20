import SwiftUI

struct FindPeopleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CKFollowService.self) private var followService
    @Environment(AppleAuthService.self) private var authService

    @State private var searchText = ""
    @State private var results: [CloudUserProfile] = []
    @State private var isSearching = false
    @State private var sentFollowIDs: Set<String> = []

    private var cloudKitService: CloudKitService = CKCloudKitService()

    private var currentUserID: String {
        authService.authState.user?.userIdentifier ?? ""
    }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty && !searchText.isEmpty && !isSearching {
                    ContentUnavailableView(
                        "no one found",
                        systemImage: "person.slash",
                        description: Text("try a different name")
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
                        title: "find your people",
                        subtitle: "search by name to discover other cat spotters"
                    )
                }
            }
            .searchable(text: $searchText, prompt: "search by name")
            .navigationTitle("find people")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: searchText) {
                await search()
            }
        }
    }

    // MARK: - Row

    private func resultRow(for user: CloudUserProfile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(CatchTheme.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? "anonymous" : user.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)

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
            Text("you")
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else if followService.isFollowing(targetID) {
            Text("following")
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else if followService.pendingRequestTo(targetID) != nil || sentFollowIDs.contains(targetID) {
            Text("requested")
                .font(.caption.weight(.medium))
                .foregroundStyle(CatchTheme.textSecondary)
        } else {
            Button {
                performFollow(targetID: targetID, isPrivate: user.isPrivate)
            } label: {
                Text(user.isPrivate ? "request" : "follow")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
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
            } catch {
                // Follow failed — button stays visible so user can retry
            }
        }
    }
}
