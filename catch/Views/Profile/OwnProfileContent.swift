import SwiftUI
import SwiftData
import AuthenticationServices
import CatchCore

struct OwnProfileContent: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppleAuthService.self) var authService
    @Environment(CKFollowService.self) var followService
    @Query private var profiles: [UserProfile]
    @Query(sort: \Cat.name) var cats: [Cat]
    @Query var encounters: [Encounter]

    @Binding var selectedTab: Int
    @State private var isShowingEditSheet = false
    @State private var isShowingCollection = false
    @State private var searchText = ""

    var cloudKitService: CloudKitService = CKCloudKitService(database: CloudKitConfiguration.publicDatabase)

    private var profile: UserProfile? { profiles.first }

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
            if profile != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(CatchTheme.primary)
                    }
                }
            }
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
        )) { profile in
            EditProfileView(profile: profile) { updatedProfile in
                syncProfileToCloudKit(updatedProfile)
            }
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
            if let data = profile.avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
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

            Button {
                createProfile()
            } label: {
                Text(CatchStrings.Profile.setUpProfile)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, CatchSpacing.space12)
                    .padding(.vertical, CatchSpacing.space8)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }
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
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleSignIn(result, profile: profile)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)

            Text(CatchStrings.Profile.signInPrompt)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)

            #if DEBUG
            Button {
                authService.debugSignIn()
                if let userID = authService.authState.user?.userIdentifier {
                    profile.appleUserID = userID
                }
            } label: {
                Text(CatchStrings.Profile.fakeSignIn)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, CatchSpacing.space16)
                    .padding(.vertical, CatchSpacing.space8)
                    .background(.red.opacity(0.8))
                    .clipShape(Capsule())
            }
            #endif
        }
    }

    // MARK: - Join Date

    private func joinDateSection(_ profile: UserProfile) -> some View {
        Text(CatchStrings.Profile.lurkingSince(profile.createdAt))
            .font(.caption)
            .foregroundStyle(CatchTheme.textSecondary)
    }

    // MARK: - Helpers

    private func createProfile() {
        let profile = UserProfile()
        modelContext.insert(profile)
        isShowingEditSheet = true
    }

    private func handleSignIn(_ result: Result<ASAuthorization, any Error>, profile: UserProfile) {
        do {
            let user = try authService.processSignInResult(result)
            profile.appleUserID = user.userIdentifier
            syncToCloudKit(profile: profile, appleUserID: user.userIdentifier)
        } catch {
            // Sign-in cancelled or failed — profile still works locally
        }
    }

    private func syncToCloudKit(profile: UserProfile, appleUserID: String) {
        Task {
            do {
                let recordName = try await cloudKitService.saveUserProfile(
                    appleUserID: appleUserID,
                    displayName: profile.displayName,
                    bio: profile.bio,
                    username: profile.username,
                    isPrivate: profile.isPrivate
                )
                profile.cloudKitRecordName = recordName
            } catch {
                // CloudKit sync failure is non-fatal
            }
        }
    }

    private func syncProfileToCloudKit(_ profile: UserProfile) {
        guard let appleUserID = profile.appleUserID else { return }
        syncToCloudKit(profile: profile, appleUserID: appleUserID)
    }
}
