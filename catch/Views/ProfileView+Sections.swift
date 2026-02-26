import SwiftUI
import AuthenticationServices

extension ProfileView {

    // MARK: - Profile Header

    func profileHeader(_ profile: UserProfile) -> some View {
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
    }

    // MARK: - Avatar

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

    // MARK: - Info

    private func infoSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 6) {
            Text(profile.displayName.isEmpty ? CatchStrings.Profile.mysteriousStranger : profile.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(CatchTheme.textPrimary)

            Text(profile.bio.isEmpty ? CatchStrings.Profile.tooCoolForBio : profile.bio)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(count: cats.count, label: CatchStrings.Profile.cats, icon: "cat.fill")
            statCard(count: encounters.count, label: CatchStrings.Profile.encounters, icon: "pawprint.fill")
        }
        .padding(.horizontal, 20)
    }

    func statCard(count: Int, label: String, icon: String) -> some View {
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

    // MARK: - Social

    private var socialSection: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SocialView(selectedTab: .followers)
            } label: {
                statCard(
                    count: followService.followers.count,
                    label: CatchStrings.Profile.followers,
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
                    label: CatchStrings.Profile.following,
                    icon: "person.badge.plus"
                )
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
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
        .padding(.horizontal, 20)
    }

    private var signedInBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(CatchTheme.primary)
            Text(CatchStrings.Profile.signedInWithApple)
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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

    // MARK: - Auth Helpers

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

    func syncProfileToCloudKit(_ profile: UserProfile) {
        guard let appleUserID = profile.appleUserID else { return }
        syncToCloudKit(profile: profile, appleUserID: appleUserID)
    }
}
