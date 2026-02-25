import SwiftUI
import SwiftData
import AuthenticationServices

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppleAuthService.self) private var authService
    @Environment(CKFollowService.self) private var followService
    @Query private var profiles: [UserProfile]
    @Query private var cats: [Cat]
    @Query private var encounters: [Encounter]

    @State private var isShowingEditSheet = false

    private var cloudKitService: CloudKitService = CKCloudKitService()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    profileContent(profile)
                } else {
                    emptyState
                }
            }
            .background(CatchTheme.background)
            .navigationTitle("profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if profile != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
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
    }

    // MARK: - Profile Content

    private func profileContent(_ profile: UserProfile) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection(profile)
                infoSection(profile)
                statsSection
                if authService.authState.isSignedIn {
                    socialSection
                }
                authSection(profile)
                joinDateSection(profile)
            }
            .padding(.vertical, 24)
        }
    }

    private func avatarSection(_ profile: UserProfile) -> some View {
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

    private func infoSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 6) {
            Text(profile.displayName.isEmpty ? "mysterious stranger" : profile.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(CatchTheme.textPrimary)

            Text(profile.bio.isEmpty ? "too cool for a bio" : profile.bio)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(count: cats.count, label: "cats", icon: "cat.fill")
            statCard(count: encounters.count, label: "encounters", icon: "pawprint.fill")
        }
        .padding(.horizontal, 20)
    }

    private func statCard(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CatchTheme.primary)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(CatchTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CatchTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CatchTheme.cornerRadius))
        .shadow(
            color: .black.opacity(CatchTheme.cardShadowOpacity),
            radius: CatchTheme.cardShadowRadius,
            y: CatchTheme.cardShadowY
        )
    }

    private var socialSection: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SocialView(selectedTab: .followers)
            } label: {
                statCard(
                    count: followService.followers.count,
                    label: "followers",
                    icon: "person.2.fill"
                )
                .overlay(alignment: .topTrailing) {
                    if followService.pendingRequests.count > 0 {
                        Text("\(followService.pendingRequests.count)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: -4, y: 4)
                    }
                }
            }

            NavigationLink {
                SocialView(selectedTab: .following)
            } label: {
                statCard(
                    count: followService.following.count,
                    label: "following",
                    icon: "person.badge.plus"
                )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private func joinDateSection(_ profile: UserProfile) -> some View {
        Text("lurking since \(profile.createdAt.formatted(.dateTime.month(.wide).year()))")
            .font(.caption)
            .foregroundStyle(CatchTheme.textSecondary)
    }

    // MARK: - Auth Section

    private func authSection(_ profile: UserProfile) -> some View {
        Group {
            if authService.authState.isSignedIn {
                signedInBadge
            } else {
                signInPrompt(profile)
            }
        }
        .padding(.horizontal, 20)
    }

    private var signedInBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(CatchTheme.primary)
            Text("signed in with apple")
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(CatchTheme.cardBackground)
        .clipShape(Capsule())
    }

    private func signInPrompt(_ profile: UserProfile) -> some View {
        VStack(spacing: 10) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleSignIn(result, profile: profile)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)

            Text("sign in to back up your profile")
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)

            #if DEBUG
            Button {
                authService.debugSignIn()
                if let userID = authService.authState.user?.userIdentifier {
                    profile.appleUserID = userID
                }
            } label: {
                Text("fake sign in (debug)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.8))
                    .clipShape(Capsule())
            }
            #endif
        }
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            EmptyStateView(
                icon: "person.crop.circle.badge.questionmark",
                title: "who even are you",
                subtitle: "set up your profile so the cats know who they're dealing with"
            )
            Button {
                createProfile()
            } label: {
                Text("set up profile")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CatchTheme.primary)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Helpers

    private func createProfile() {
        let profile = UserProfile()
        modelContext.insert(profile)
        isShowingEditSheet = true
    }
}
