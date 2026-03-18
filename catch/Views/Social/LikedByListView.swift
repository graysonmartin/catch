import SwiftUI
import CatchCore

private enum Layout {
    static let avatarSize: CGFloat = 40
    static let avatarFontSize: CGFloat = 16
}

struct LikedByListView: View {
    let encounterRecordName: String

    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(\.dismiss) private var dismiss

    @State private var users: [LikedByUser] = []
    @State private var isLoading = false
    @State private var hasMore = false
    @State private var cursor: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && users.isEmpty {
                    PawLoadingView()
                } else if users.isEmpty {
                    emptyState
                } else {
                    userList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Interaction.likedBy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(CatchStrings.Common.done) { dismiss() }
                }
            }
            .navigationDestination(for: RemoteProfileRoute.self) { route in
                RemoteProfileContent(
                    userID: route.userID,
                    initialDisplayName: route.displayName
                )
            }
            .task { await loadLikes() }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        EmptyStateView(
            icon: "heart",
            title: CatchStrings.Interaction.noLikesTitle,
            subtitle: CatchStrings.Interaction.noLikesSubtitle
        )
    }

    private var userList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(users) { user in
                    NavigationLink(value: RemoteProfileRoute(
                        userID: user.userID,
                        displayName: user.displayName
                    )) {
                        LikedByRow(user: user)
                    }
                    .buttonStyle(.plain)

                    if user.id != users.last?.id {
                        Divider()
                            .padding(.leading, Layout.avatarSize + CatchSpacing.space12 + CatchSpacing.space16)
                    }
                }

                if hasMore {
                    loadMoreRow
                }
            }
            .padding(.vertical, CatchSpacing.space8)
        }
    }

    @ViewBuilder
    private var loadMoreRow: some View {
        if isLoading {
            PawLoadingView(size: .inline)
                .padding()
        } else {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    Task { await loadMoreLikes() }
                }
        }
    }

    // MARK: - Actions

    private func loadLikes() async {
        guard let socialService else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (fetched, nextCursor) = try await socialService.fetchLikes(
                encounterRecordName: encounterRecordName,
                cursor: nil
            )
            users = fetched
            cursor = nextCursor
            hasMore = nextCursor != nil
        } catch {
            // Likes fail silently — not critical path
        }
    }

    private func loadMoreLikes() async {
        guard let socialService, let cursor else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (fetched, nextCursor) = try await socialService.fetchLikes(
                encounterRecordName: encounterRecordName,
                cursor: cursor
            )
            users.append(contentsOf: fetched)
            self.cursor = nextCursor
            hasMore = nextCursor != nil
        } catch {
            // Pagination fail silently
        }
    }
}

// MARK: - Row

private struct LikedByRow: View {
    let user: LikedByUser

    var body: some View {
        HStack(spacing: CatchSpacing.space12) {
            avatar
            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textPrimary)
                if let username = user.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, CatchSpacing.space16)
        .padding(.vertical, CatchSpacing.space10)
    }

    private var avatar: some View {
        Group {
            if let url = user.avatarURL, !url.isEmpty {
                UserAvatarView(avatarURL: url, size: Layout.avatarSize)
            } else {
                Circle()
                    .fill(CatchTheme.secondary)
                    .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                    .overlay {
                        Text(String(user.displayName.prefix(1)).uppercased())
                            .font(.system(size: Layout.avatarFontSize, weight: .bold))
                            .foregroundStyle(CatchTheme.primary)
                    }
            }
        }
    }
}
