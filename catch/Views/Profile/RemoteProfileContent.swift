import SwiftUI
import CatchCore

struct RemoteProfileContent: View {
    let userID: String
    let initialDisplayName: String?

    @Environment(CKFollowService.self) private var followService
    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @Environment(AppleAuthService.self) private var authService
    @Environment(CKSocialInteractionService.self) private var socialService: CKSocialInteractionService?

    @State private var data: UserBrowseData?
    @State private var loadError: UserBrowseError?
    @State private var isShowingCollection = false
    @State private var isShowingBreedLog = false
    @State private var isShowingUnfollowConfirmation = false
    @State private var selectedEncounterDetail: EncounterDetailData?

    var body: some View {
        Group {
            if browseService?.isLoading == true && data == nil {
                loadingState
            } else if let data {
                if data.profile.isPrivate && !isFollowingUser {
                    privateProfileState(data: data)
                } else {
                    profileContent(data: data)
                }
            } else if let loadError {
                errorState(loadError)
            } else {
                loadingState
            }
        }
        .background(CatchTheme.background)
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isPrivateHidden {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarFollowButton
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: CatchSpacing.space12) {
            ProgressView()
                .tint(CatchTheme.primary)
            Text(CatchStrings.Social.loadingProfile)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func privateProfileState(data: UserBrowseData) -> some View {
        VStack(spacing: CatchSpacing.space16) {
            avatarWithSocial(data: data)

            ProfileHeaderView(
                data: ProfileDisplayData(remote: data),
                showAvatar: false
            )

            inlineFollowButton

            VStack(spacing: CatchSpacing.space8) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(CatchTheme.textSecondary)
                Text(CatchStrings.Social.profileIsPrivate)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
                Text(CatchStrings.Social.followToSee)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
            .padding(.top, CatchSpacing.space32)

            Spacer()
        }
        .padding()
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
            compactSocialStat(
                count: data.followerCount,
                label: CatchStrings.Profile.followers
            )

            avatarImage(data: data)

            compactSocialStat(
                count: data.followingCount,
                label: CatchStrings.Profile.following
            )
        }
        .padding(.horizontal, CatchSpacing.space20)
    }

    @ViewBuilder
    private func avatarImage(data: UserBrowseData) -> some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .foregroundStyle(CatchTheme.secondary)
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
                ownerName: data.profile.displayName
            )
        }
        .navigationDestination(isPresented: $isShowingBreedLog) {
            BreedLogView(entries: breedLogEntries(data: data))
        }
    }

    // MARK: - Follow Button (Toolbar)

    @ViewBuilder
    private var toolbarFollowButton: some View {
        let currentUserID = authService.authState.user?.userIdentifier ?? ""
        if userID != currentUserID {
            if followService.isFollowing(userID) {
                Button {
                    isShowingUnfollowConfirmation = true
                } label: {
                    Text(CatchStrings.Social.followingStatus)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatchTheme.textPrimary)
                }
                .confirmationDialog(
                    CatchStrings.Social.areYouSure,
                    isPresented: $isShowingUnfollowConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(CatchStrings.Social.unfollow, role: .destructive) {
                        Task {
                            try? await followService.unfollow(targetID: userID, by: currentUserID)
                        }
                    }
                } message: {
                    Text(CatchStrings.Social.unfollowConfirmMessage)
                }
            } else if followService.pendingRequestTo(userID) != nil {
                Text(CatchStrings.Social.requestedStatus)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CatchTheme.textSecondary)
            } else {
                Button {
                    Task {
                        let isPrivate = data?.profile.isPrivate ?? false
                        try? await followService.follow(
                            targetID: userID,
                            by: currentUserID,
                            isTargetPrivate: isPrivate
                        )
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

    // MARK: - Follow Button (Inline for Private)

    @ViewBuilder
    private var inlineFollowButton: some View {
        let currentUserID = authService.authState.user?.userIdentifier ?? ""
        if userID != currentUserID {
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
                        let isPrivate = data?.profile.isPrivate ?? false
                        try? await followService.follow(
                            targetID: userID,
                            by: currentUserID,
                            isTargetPrivate: isPrivate
                        )
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

    private var isFollowingUser: Bool {
        followService.isFollowing(userID)
    }

    private var isPrivateHidden: Bool {
        guard let data else { return false }
        return data.profile.isPrivate && !isFollowingUser
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
        try? await socialService.loadInteractionData(for: recordNames)
    }
}
