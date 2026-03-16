import SwiftUI
import CatchCore

struct OwnProfileContent: View {
    @Environment(SupabaseAuthService.self) var authService
    @Environment(SupabaseFollowService.self) var followService
    @Environment(ProfileSyncService.self) private var profileSyncService
    @Environment(CatDataService.self) private var catDataService
    @Environment(ToastManager.self) private var toastManager

    @Binding var selectedTab: Int
    @State private var profile: UserProfile?
    @State private var isShowingEditSheet = false
    @State private var isShowingFindPeople = false
    @State private var isShowingCollection = false
    @State private var searchText = ""

    private var cats: [Cat] { catDataService.cats }

    private var encounters: [Encounter] {
        cats.flatMap { cat in
            cat.encounters.map { enc in
                var e = enc
                e.cat = cat
                return e
            }
        }.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CatchSpacing.space24) {
                if let profile {
                    profileHeader(profile)
                } else {
                    setupBanner
                }

                ProfileDiaryTab(
                    encounters: encounters,
                    searchText: searchText
                )

                if let profile {
                    authSection(profile)
                    joinDateSection(profile)
                }
            }
            .padding(.vertical, CatchSpacing.space24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CatchTheme.background)
        .navigationTitle(CatchStrings.Profile.profileTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: CatchStrings.Diary.searchPrompt)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(CatchTheme.primary)
                }
            }

            if profile != nil, authService.authState.isSignedIn {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: CatchSpacing.space16) {
                        Button {
                            isShowingFindPeople = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(CatchTheme.primary)
                        }

                        Button {
                            isShowingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(CatchTheme.primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingFindPeople) {
            FindPeopleView()
        }
        .navigationDestination(for: Cat.self) { cat in
            CatProfileView(cat: cat)
        }
        .navigationDestination(isPresented: $isShowingCollection) {
            ProfileCollectionTab(selectedTab: $selectedTab)
        }
        .sheet(item: Binding(
            get: { isShowingEditSheet ? profile : nil },
            set: { _ in isShowingEditSheet = false }
        )) { editProfile in
            EditProfileView(profile: editProfile) { updatedProfile in
                profile = updatedProfile
                syncProfile(updatedProfile)
            }
        }
        .task {
            await loadProfile()
        }
    }

    // MARK: - Data Loading

    private func loadProfile() async {
        guard let userID = authService.authState.user?.id else { return }
        do {
            if let cloudProfile = try await profileSyncService.fetchProfile(userID: userID) {
                profile = UserProfile(
                    displayName: cloudProfile.displayName,
                    bio: cloudProfile.bio,
                    username: cloudProfile.username,
                    supabaseUserID: userID,
                    isPrivate: cloudProfile.isPrivate,
                    avatarUrl: cloudProfile.avatarURL
                )
            }
        } catch {
            // Profile load failure is non-critical
        }
    }

    // MARK: - Profile Header

    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: CatchSpacing.space24) {
            avatarWithSocial(profile)

            ProfileHeaderView(
                data: ProfileDisplayData(
                    local: profile,
                    catCount: cats.count,
                    encounterCount: encounters.count
                ),
                showAvatar: false
            )

            statsSection
        }
    }

    // MARK: - Avatar with Social

    private func avatarWithSocial(_ profile: UserProfile) -> some View {
        HStack(alignment: .center, spacing: CatchSpacing.space24) {
            if authService.authState.isSignedIn {
                NavigationLink {
                    SocialView(selectedTab: .followers)
                } label: {
                    compactSocialStat(
                        count: followService.followers.count,
                        label: CatchStrings.Profile.followers
                    )
                    .overlay(alignment: .topTrailing) {
                        if followService.pendingRequests.count > 0 {
                            Text("\(followService.pendingRequests.count)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
            }

            avatarImage(profile)

            if authService.authState.isSignedIn {
                NavigationLink {
                    SocialView(selectedTab: .following)
                } label: {
                    compactSocialStat(
                        count: followService.following.count,
                        label: CatchStrings.Profile.following
                    )
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, CatchSpacing.space20)
    }

    private func avatarImage(_ profile: UserProfile) -> some View {
        Group {
            if let avatarUrl = profile.avatarUrl {
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

    private var statsSection: some View {
        HStack(spacing: CatchSpacing.space10) {
            Button {
                isShowingCollection = true
            } label: {
                StatCardView(count: cats.count, label: CatchStrings.Profile.cats, icon: "cat.fill", showChevron: true)
            }
            .buttonStyle(.plain)

            StatCardView(count: encounters.count, label: CatchStrings.Profile.encounters, icon: "pawprint.fill")

            NavigationLink {
                BreedLogView()
            } label: {
                StatCardView(count: breedCount, label: CatchStrings.Profile.breedLog, icon: "book.closed.fill", showChevron: true)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, CatchSpacing.space20)
    }

    private var breedCount: Int {
        Set(cats.compactMap(\.breed)).count
    }

    // MARK: - Setup Banner

    private var setupBanner: some View {
        HStack(spacing: CatchSpacing.space12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.title2)
                .foregroundStyle(CatchTheme.primary)

            VStack(alignment: .leading, spacing: CatchSpacing.space2) {
                Text(CatchStrings.Profile.emptyTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CatchTheme.textPrimary)
                Text(CatchStrings.Profile.emptySubtitle)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(CatchSpacing.space16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
        .padding(.horizontal)
    }

    // MARK: - Auth

    private func authSection(_ profile: UserProfile) -> some View {
        Group {
            if authService.authState.isSignedIn {
                signedInBadge
            } else {
                signInPrompt(profile)
            }
        }
        .padding(.horizontal, CatchSpacing.space20)
    }

    private var signedInBadge: some View {
        HStack(spacing: CatchSpacing.space8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(CatchTheme.primary)
            Text(CatchStrings.Profile.signedInWithApple)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .padding(.vertical, CatchSpacing.space12)
        .padding(.horizontal, CatchSpacing.space20)
        .background(CatchTheme.cardBackground)
        .clipShape(Capsule())
    }

    private func signInPrompt(_ profile: UserProfile) -> some View {
        VStack(spacing: CatchSpacing.space10) {
            Text(CatchStrings.Profile.signInPrompt)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
    }

    // MARK: - Join Date

    private func joinDateSection(_ profile: UserProfile) -> some View {
        Text(CatchStrings.Profile.lurkingSince(profile.createdAt))
            .font(.caption)
            .foregroundStyle(CatchTheme.textSecondary)
    }

    // MARK: - Helpers

    private func syncProfile(_ profile: UserProfile) {
        Task {
            do {
                try await profileSyncService.syncProfile(profile)
            } catch {
                toastManager.showError(CatchStrings.Toast.profileSaveFailed)
            }
        }
    }
}
