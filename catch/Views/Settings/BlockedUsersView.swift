import SwiftUI
import CatchCore

struct BlockedUsersView: View {
    @Environment(SupabaseBlockService.self) private var blockService
    @Environment(SupabaseUserBrowseService.self) private var browseService: SupabaseUserBrowseService?
    @Environment(ToastManager.self) private var toastManager

    @State private var profiles: [String: CloudUserProfile] = [:]
    @State private var isLoading = true
    @State private var unblockTarget: String?

    private var sortedBlockedIDs: [String] {
        Array(blockService.blockedUserIDs).sorted()
    }

    var body: some View {
        Group {
            if isLoading {
                PawLoadingView(label: CatchStrings.Social.loadingProfile)
            } else if sortedBlockedIDs.isEmpty {
                emptyState
            } else {
                blockedList
            }
        }
        .navigationTitle(CatchStrings.Block.blockedUsersTitle)
        .navigationBarTitleDisplayMode(.inline)
        .background(CatchTheme.background)
        .task { await loadProfiles() }
        .confirmationDialog(
            CatchStrings.Block.unblockConfirmTitle,
            isPresented: showingUnblockConfirm,
            titleVisibility: .visible
        ) {
            Button(CatchStrings.Block.unblock, role: .destructive) {
                guard let targetID = unblockTarget else { return }
                Task { await performUnblock(targetID) }
            }
        } message: {
            Text(CatchStrings.Block.unblockConfirmMessage)
        }
    }

    private var showingUnblockConfirm: Binding<Bool> {
        Binding(
            get: { unblockTarget != nil },
            set: { if !$0 { unblockTarget = nil } }
        )
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "hand.raised.slash",
            title: CatchStrings.Block.noBlockedUsers,
            subtitle: CatchStrings.Block.noBlockedUsersSubtitle
        )
    }

    private var blockedList: some View {
        List {
            ForEach(sortedBlockedIDs, id: \.self) { userID in
                blockedRow(userID: userID)
            }
        }
        .listStyle(.plain)
    }

    private func blockedRow(userID: String) -> some View {
        HStack(spacing: CatchSpacing.space12) {
            avatarView(for: userID)

            Text(profiles[userID]?.displayName ?? CatchStrings.Social.profileFallbackTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.textPrimary)

            Spacer()

            Button {
                unblockTarget = userID
            } label: {
                Text(CatchStrings.Block.unblock)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.primary)
                    .padding(.horizontal, CatchSpacing.space12)
                    .padding(.vertical, CatchSpacing.space6)
                    .background(CatchTheme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, CatchSpacing.space4)
    }

    @ViewBuilder
    private func avatarView(for userID: String) -> some View {
        if let avatarUrl = profiles[userID]?.avatarURL, !avatarUrl.isEmpty {
            RemoteImageView(urlString: avatarUrl) {
                avatarPlaceholder
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .foregroundStyle(CatchTheme.secondary)
    }

    private func loadProfiles() async {
        guard let browseService else {
            isLoading = false
            return
        }
        let ids = Array(blockService.blockedUserIDs)
        guard !ids.isEmpty else {
            isLoading = false
            return
        }
        profiles = await browseService.batchFetchProfiles(userIDs: ids)
        isLoading = false
    }

    private func performUnblock(_ targetID: String) async {
        do {
            try await blockService.unblockUser(targetID)
            profiles.removeValue(forKey: targetID)
            toastManager.showSuccess(CatchStrings.Toast.unblockSuccess)
        } catch is RateLimitError {
            toastManager.showError(CatchStrings.Toast.rateLimitedBlock)
        } catch {
            toastManager.showError(CatchStrings.Toast.unblockFailed)
        }
    }
}
