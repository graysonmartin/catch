import SwiftUI

struct UserPublicProfileView: View {
    let userID: String
    let initialDisplayName: String?

    @Environment(CKFollowService.self) private var followService
    @Environment(CKUserBrowseService.self) private var browseService: CKUserBrowseService?
    @Environment(AppleAuthService.self) private var authService

    @State private var data: UserBrowseData?
    @State private var loadError: UserBrowseError?
    @State private var selectedTab: ProfileTab = .cats

    private enum ProfileTab: String, CaseIterable, Identifiable {
        case cats
        case activity

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .cats: CatchStrings.Social.catsTab
            case .activity: CatchStrings.Social.activityTab
            }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: CatchSpacing.space16),
        GridItem(.flexible(), spacing: CatchSpacing.space16)
    ]

    var body: some View {
        Group {
            if browseService?.isLoading == true && data == nil {
                loadingState
            } else if let data {
                if data.profile.isPrivate && !isFollowingUser {
                    privateProfileState(profile: data.profile)
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
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
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

    private func privateProfileState(profile: CloudUserProfile) -> some View {
        VStack(spacing: CatchSpacing.space16) {
            profileHeader(profile: profile)
            followButton

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
            VStack(spacing: CatchSpacing.space16) {
                profileHeader(profile: data.profile)
                followButton
                tabPicker
                tabContent(data: data)
            }
            .padding()
        }
    }

    private func profileHeader(profile: CloudUserProfile) -> some View {
        VStack(spacing: CatchSpacing.space8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(CatchTheme.secondary)

            Text(profile.displayName)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let data {
                HStack(spacing: CatchSpacing.space24) {
                    statBadge(count: isPrivateHidden ? nil : data.cats.count, label: CatchStrings.Profile.cats)
                    statBadge(count: isPrivateHidden ? nil : data.encounters.count, label: CatchStrings.Profile.encounters)
                }
                .padding(.top, CatchSpacing.space4)
            }
        }
    }

    private func statBadge(count: Int?, label: String) -> some View {
        VStack(spacing: CatchSpacing.space2) {
            Text(count.map { "\($0)" } ?? CatchStrings.Social.statPlaceholder)
                .font(.headline)
                .foregroundStyle(CatchTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var followButton: some View {
        let currentUserID = authService.authState.user?.userIdentifier ?? ""
        if userID != currentUserID {
            if followService.isFollowing(userID) {
                Button(CatchStrings.Social.followingStatus) {
                    Task {
                        try? await followService.unfollow(targetID: userID, by: currentUserID)
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.textPrimary)
                .padding(.horizontal, CatchSpacing.space24)
                .padding(.vertical, CatchSpacing.space8)
                .background(CatchTheme.secondary)
                .clipShape(Capsule())
            } else if followService.pendingRequestTo(userID) != nil {
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

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(ProfileTab.allCases) { tab in
                Text(tab.displayName).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func tabContent(data: UserBrowseData) -> some View {
        switch selectedTab {
        case .cats:
            catsGrid(data: data)
        case .activity:
            activityFeed(data: data)
        }
    }

    private func catsGrid(data: UserBrowseData) -> some View {
        Group {
            if data.cats.isEmpty {
                EmptyStateView(
                    icon: "square.grid.2x2",
                    title: CatchStrings.Social.noCatsYetTitle,
                    subtitle: CatchStrings.Social.noCatsYetSubtitle
                )
                .padding(.top, CatchSpacing.space32)
            } else {
                LazyVGrid(columns: columns, spacing: CatchSpacing.space16) {
                    ForEach(data.cats, id: \.recordName) { cat in
                        let encounterCount = data.encounters.filter { $0.catRecordName == cat.recordName }.count
                        NavigationLink {
                            RemoteCatProfileView(
                                cat: cat,
                                encounters: data.encounters,
                                ownerName: data.profile.displayName
                            )
                        } label: {
                            RemoteCatCardView(cat: cat, encounterCount: encounterCount)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func activityFeed(data: UserBrowseData) -> some View {
        Group {
            if data.encounters.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: CatchStrings.Social.noActivityTitle,
                    subtitle: CatchStrings.Social.noActivitySubtitle
                )
                .padding(.top, CatchSpacing.space32)
            } else {
                let sorted = data.encounters.sorted { $0.date > $1.date }
                LazyVStack(spacing: CatchSpacing.space12) {
                    ForEach(sorted, id: \.recordName) { encounter in
                        let cat = data.cats.first { $0.recordName == encounter.catRecordName }
                        RemoteFeedItemView(encounter: encounter, cat: cat)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var displayName: String {
        data?.profile.displayName ?? initialDisplayName ?? CatchStrings.Social.profileFallbackTitle
    }

    private var isFollowingUser: Bool {
        followService.isFollowing(userID)
    }

    private var isPrivateHidden: Bool {
        guard let data else { return false }
        return data.profile.isPrivate && !isFollowingUser
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
}
