import SwiftUI
import CatchCore

struct RemoteProfileContent: View {
    let userID: String
    let initialDisplayName: String?

    @Environment(SupabaseFollowService.self) private var followService
    @Environment(SupabaseUserBrowseService.self) private var browseService: SupabaseUserBrowseService?
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(SupabaseSocialInteractionService.self) private var socialService: SupabaseSocialInteractionService?
    @Environment(SupabaseBlockService.self) private var blockService
    @Environment(ToastManager.self) private var toastManager

    @State private var data: UserBrowseData?
    @State private var loadError: UserBrowseError?
    @State private var isShowingCollection = false
    @State private var isShowingBreedLog = false
    @State private var isShowingUnfollowConfirmation = false
    @State private var isShowingBlockConfirmation = false
    @State private var selectedEncounterDetail: EncounterDetailData?
    @State private var followerCountAdjustment = 0

    var body: some View {
        Group {
            if browseService?.isLoading == true && data == nil {
                loadingState
            } else if let data {
                profileContent(data: data)
            } else if let loadError {
                errorState(loadError)
            } else {
                loadingState
            }
        }
        .background(CatchTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isOwnProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarFollowButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarOverflowMenu
                }
            }
        }
        .confirmationDialog(
            CatchStrings.Block.blockConfirmTitle,
            isPresented: $isShowingBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(CatchStrings.Block.blockUser, role: .destructive) {
                Task { await performBlock() }
            }
        } message: {
            Text(CatchStrings.Block.blockConfirmMessage)
        }
        .task {
            await loadData()
        }
    }

    // MARK: - States

    private var loadingState: some View {
        PawLoadingView(label: CatchStrings.Social.loadingProfile)
    }

    private func errorState(_ error: UserBrowseError) -> some View {
        VStack(spacing: CatchSpacing.space12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(CatchTheme.textSecondary)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
            Button(CatchStrings.Social.tryAgain) {
                Task { await loadData() }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(CatchTheme.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Profile content

    private func profileContent(data: UserBrowseData) -> some View {
        ScrollView {
            VStack(spacing: CatchSpacing.space24) {
                avatarWithSocial(data: data)

                ProfileHeaderView(
                    data: ProfileDisplayData(remote: data),
                    showAvatar: false
                )

                statsSection(data: data)
                diaryFeed(data: data)
            }
            .padding(.vertical, CatchSpacing.space24)
        }
    }

    // MARK: - Avatar with Social

    private func avatarWithSocial(data: UserBrowseData) -> some View {
        HStack(alignment: .center, spacing: CatchSpacing.space24) {
            NavigationLink {
                RemoteFollowListView(
                    userID: userID,
                    displayName: data.profile.displayName,
                    tab: .followers
                )
            } label: {
                compactSocialStat(
                    count: max(0, data.followerCount + followerCountAdjustment),
                    label: CatchStrings.Profile.followers
                )
            }
            .buttonStyle(.plain)

            avatarImage(data: data)

            NavigationLink {
                RemoteFollowListView(
                    userID: userID,
                    displayName: data.profile.displayName,
                    tab: .following
                )
            } label: {
                compactSocialStat(
                    count: data.followingCount,
                    label: CatchStrings.Profile.following
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CatchSpacing.space20)
    }

    @ViewBuilder
    private func avatarImage(data: UserBrowseData) -> some View {
        if let avatarUrl = data.profile.avatarURL, !avatarUrl.isEmpty {
            RemoteImageView(urlString: avatarUrl) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(CatchTheme.secondary)
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(CatchTheme.secondary)
        }
    }

    private func compactSocialStat(count: Int, label: String) -> some View {
        VStack(spacing: CatchSpacing.space4) {
            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            RoundedRectangle(cornerRadius: 1)
                .fill(CatchTheme.primary)
                .frame(width: 32, height: 2)

            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(minWidth: 60)
    }

    // MARK: - Stats

    private func statsSection(data: UserBrowseData) -> some View {
        HStack(spacing: CatchSpacing.space10) {
            Button {
                isShowingCollection = true
            } label: {
                StatCardView(
                    count: data.cats.count,
                    label: CatchStrings.Profile.cats,
                    icon: "cat.fill",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            StatCardView(
                count: data.encounters.count,
                label: CatchStrings.Profile.encounters,
                icon: "pawprint.fill"
            )

            Button {
                isShowingBreedLog = true
            } label: {
                StatCardView(
                    count: breedCount(data: data),
                    label: CatchStrings.Profile.breedLog,
                    icon: "book.closed.fill",
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CatchSpacing.space20)
        .navigationDestination(isPresented: $isShowingCollection) {
            RemoteCollectionTab(
                cats: data.cats,
                encounters: data.encounters,
                owner: data.profile
            )
        }
        .navigationDestination(isPresented: $isShowingBreedLog) {
            BreedLogView(entries: breedLogEntries(data: data), cloudCats: data.cats)
        }
    }

    // MARK: - Follow Button (Toolbar)

    @ViewBuilder
    private var toolbarFollowButton: some View {
        if !isOwnProfile {
            if followService.isFollowing(userID) {
                Button {
                    isShowingUnfollowConfirmation = true
                } label: {
                    Text(CatchStrings.Social.followingStatus)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                        .padding(.horizontal, CatchSpacing.space12)
                        .padding(.vertical, CatchSpacing.space6)
                        .background(CatchTheme.textSecondary.opacity(0.15))
                        .clipShape(Capsule())
                }
                .confirmationDialog(
                    CatchStrings.Social.areYouSure,
                    isPresented: $isShowingUnfollowConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(CatchStrings.Social.unfollow, role: .destructive) {
                        Task {
                            followerCountAdjustment -= 1
                            do {
                                try await followService.unfollow(targetID: userID, by: authenticatedUserID)
                                browseService?.invalidateCache(for: userID)
                            } catch is RateLimitError {
                                followerCountAdjustment += 1
                                toastManager.showError(CatchStrings.Toast.rateLimitedFollow)
                            } catch {
                                followerCountAdjustment += 1
                                toastManager.showError(CatchStrings.Toast.unfollowFailed)
                            }
                        }
                    }
                } message: {
                    Text(CatchStrings.Social.unfollowConfirmMessage)
                }
            } else if followService.pendingRequestTo(userID) != nil {
                Text(CatchStrings.Social.requestedStatus)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .padding(.horizontal, CatchSpacing.space12)
                    .padding(.vertical, CatchSpacing.space6)
                    .background(CatchTheme.textSecondary.opacity(0.15))
                    .clipShape(Capsule())
            } else {
                Button {
                    Task {
                        followerCountAdjustment += 1
                        do {
                            try await followService.follow(
                                targetID: userID,
                                by: authenticatedUserID,
                                isTargetPrivate: false
                            )
                            browseService?.invalidateCache(for: userID)
                        } catch is RateLimitError {
                            if !isPrivate {
                                followerCountAdjustment -= 1
                            }
                            toastManager.showError(CatchStrings.Toast.rateLimitedFollow)
                        } catch {
                            followerCountAdjustment -= 1
                            toastManager.showError(CatchStrings.Toast.followFailed)
                        }
                    }
                } label: {
                    Text(CatchStrings.Social.follow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, CatchSpacing.space12)
                        .padding(.vertical, CatchSpacing.space6)
                        .background(CatchTheme.primary)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Overflow Menu

    private var toolbarOverflowMenu: some View {
        Menu {
            if blockService.isBlocked(userID) {
                Button {
                    Task { await performUnblock() }
                } label: {
                    Label(CatchStrings.Block.unblockUser, systemImage: "hand.raised.slash")
                }
            } else {
                Button(role: .destructive) {
                    isShowingBlockConfirmation = true
                } label: {
                    Label(CatchStrings.Block.blockUser, systemImage: "hand.raised")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundStyle(CatchTheme.textPrimary)
        }
    }

    private func performBlock() async {
        do {
            try await blockService.blockUser(userID)
            if followService.isFollowing(userID) {
                try? await followService.unfollow(targetID: userID, by: authenticatedUserID)
            }
            browseService?.invalidateCache(for: userID)
            toastManager.showSuccess(CatchStrings.Toast.blockSuccess)
        } catch is RateLimitError {
            toastManager.showError(CatchStrings.Toast.rateLimitedBlock)
        } catch {
            toastManager.showError(CatchStrings.Toast.blockFailed)
        }
    }

    private func performUnblock() async {
        do {
            try await blockService.unblockUser(userID)
            browseService?.invalidateCache(for: userID)
            toastManager.showSuccess(CatchStrings.Toast.unblockSuccess)
        } catch is RateLimitError {
            toastManager.showError(CatchStrings.Toast.rateLimitedBlock)
        } catch {
            toastManager.showError(CatchStrings.Toast.unblockFailed)
        }
    }

    // MARK: - Follow Button (Inline for Private)

    @ViewBuilder
    private var inlineFollowButton: some View {
        if !isOwnProfile {
            if followService.pendingRequestTo(userID) != nil {
                Text(CatchStrings.Social.requestedStatus)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CatchTheme.textSecondary)
                    .padding(.horizontal, CatchSpacing.space24)
                    .padding(.vertical, CatchSpacing.space8)
                    .background(CatchTheme.textSecondary.opacity(0.1))
                    .clipShape(Capsule())
            } else {
                Button(CatchStrings.Social.follow) {
                    Task {
                        do {
                            try await followService.follow(
                                targetID: userID,
                                by: authenticatedUserID,
                                isTargetPrivate: true
                            )
                            browseService?.invalidateCache(for: userID)
                        } catch is RateLimitError {
                            toastManager.showError(CatchStrings.Toast.rateLimitedFollow)
                        } catch {
                            toastManager.showError(CatchStrings.Toast.followFailed)
                        }
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, CatchSpacing.space24)
                .padding(.vertical, CatchSpacing.space8)
                .background(CatchTheme.primary)
                .clipShape(Capsule())
            }
        }
    }


    // MARK: - Diary Feed

    private var isShowingDetail: Binding<Bool> {
        Binding(
            get: { selectedEncounterDetail != nil },
            set: { if !$0 { selectedEncounterDetail = nil } }
        )
    }

    private func diaryFeed(data: UserBrowseData) -> some View {
        Group {
            if data.encounters.isEmpty {
                EmptyStateView(
                    icon: "book.closed",
                    title: CatchStrings.Diary.noDiaryTitle,
                    subtitle: CatchStrings.Diary.noDiarySubtitle
                )
                .padding(.top, CatchSpacing.space32)
            } else {
                let grouped = groupedEncounters(data.encounters)
                let firstEncounterIDs = earliestEncounterIDs(data.encounters)
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(grouped, id: \.date) { group in
                        Section {
                            ForEach(group.encounters, id: \.recordName) { encounter in
                                let cat = data.cats.first { $0.recordName == encounter.catRecordName }
                                remoteDiaryRow(
                                    encounter: encounter,
                                    cat: cat,
                                    isFirstEncounter: firstEncounterIDs.contains(encounter.recordName)
                                )
                            }
                        } header: {
                            Text(formattedDateHeader(group.date))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CatchTheme.textSecondary)
                                .padding(.top, CatchSpacing.space16)
                                .padding(.bottom, CatchSpacing.space4)
                        }
                    }
                }
                .padding(.horizontal)
                .task {
                    await loadInteractionData(for: data.encounters)
                }
            }
        }
        .sheet(isPresented: isShowingDetail) {
            if let detail = selectedEncounterDetail {
                EncounterDetailSheet(data: detail)
            }
        }
    }

    private func remoteDiaryRow(
        encounter: CloudEncounter,
        cat: CloudCat?,
        isFirstEncounter: Bool
    ) -> some View {
        Button {
            selectedEncounterDetail = EncounterDetailData(
                remote: encounter,
                cat: cat,
                isFirstEncounter: isFirstEncounter
            )
        } label: {
            RemoteDiaryEntryRow(
                encounter: encounter,
                cat: cat,
                isFirstEncounter: isFirstEncounter,
                likeCount: socialService?.likeCount(for: encounter.recordName) ?? 0,
                commentCount: socialService?.commentCount(for: encounter.recordName) ?? 0
            )
        }
        .buttonStyle(.plain)
    }

    private func earliestEncounterIDs(_ encounters: [CloudEncounter]) -> Set<String> {
        var ids = Set<String>()
        var seenCats = Set<String>()
        let allSorted = encounters.sorted { $0.date < $1.date }
        for encounter in allSorted {
            if !seenCats.contains(encounter.catRecordName) {
                seenCats.insert(encounter.catRecordName)
                ids.insert(encounter.recordName)
            }
        }
        return ids
    }

    private func groupedEncounters(_ encounters: [CloudEncounter]) -> [(date: Date, encounters: [CloudEncounter])] {
        let grouped = Dictionary(grouping: encounters) { encounter in
            Calendar.current.startOfDay(for: encounter.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, encounters: $0.value.sorted { $0.date > $1.date }) }
    }

    private func formattedDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day()).lowercased()
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day().year()).lowercased()
        }
    }

    // MARK: - Helpers

    private var displayTitle: String {
        data?.profile.displayName ?? initialDisplayName ?? CatchStrings.Social.profileFallbackTitle
    }

    private var isOwnProfile: Bool {
        guard let currentUserID = authService.authState.user?.id else { return false }
        return userID == currentUserID
    }

    private var authenticatedUserID: String {
        authService.authState.user?.id ?? ""
    }

    private var isPrivate: Bool {
        data?.profile.isPrivate ?? false
    }

    private func breedCount(data: UserBrowseData) -> Int {
        Set(data.cats.map(\.breed).filter { BreedCatalog.contains($0) }).count
    }

    private func breedLogEntries(data: UserBrowseData) -> [BreedLogEntry] {
        DefaultBreedLogService().buildBreedLog(from: data.cats)
    }

    private func loadData() async {
        guard let browseService else { return }
        loadError = nil
        do {
            data = try await browseService.fetchUserData(userID: userID)
            followerCountAdjustment = 0
        } catch let error as UserBrowseError {
            loadError = error
        } catch {
            loadError = .networkError(error.localizedDescription)
        }
    }

    private func loadInteractionData(for encounters: [CloudEncounter]) async {
        guard let socialService else { return }
        let recordNames = encounters.map(\.recordName)
        guard !recordNames.isEmpty else { return }
        do {
            try await socialService.loadInteractionData(for: recordNames)
        } catch where error.isCancellation {
        } catch {
            toastManager.showError(CatchStrings.Toast.feedLoadFailed)
        }
    }
}
