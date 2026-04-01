import SwiftUI
import CatchCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SupabaseAuthService.self) private var authService
    @Environment(ProfileSyncService.self) private var profileSyncService

    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetup = false

    @State private var settingsService: SettingsService = UserDefaultsSettingsService()
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingSignOutConfirmation = false

    var body: some View {
        Form {
            aboutSection
            DataExportSection()
            legalSection
            dangerZoneSection
            #if DEBUG
            debugSection
            #endif
        }
        .navigationTitle(CatchStrings.Settings.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(CatchTheme.background)
        .alert(
            CatchStrings.Settings.deleteAccountConfirmTitle,
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button(CatchStrings.Settings.deleteAccountConfirm, role: .destructive) {
                deleteAccount()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) { }
        } message: {
            Text(CatchStrings.Settings.deleteAccountConfirmMessage)
        }
        .alert(
            CatchStrings.Settings.signOutConfirmTitle,
            isPresented: $isShowingSignOutConfirmation
        ) {
            Button(CatchStrings.Settings.signOutConfirm, role: .destructive) {
                performSignOut()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) { }
        } message: {
            Text(CatchStrings.Settings.signOutConfirmMessage)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        Section {
            Link(destination: AppURL.privacyPolicy) {
                HStack {
                    Image(systemName: "hand.raised")
                    Text(CatchStrings.Settings.privacyPolicy)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }

            Link(destination: AppURL.termsOfService) {
                HStack {
                    Image(systemName: "doc.text")
                    Text(CatchStrings.Settings.termsOfService)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }
        } header: {
            Text(CatchStrings.Settings.legalSection)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text(CatchStrings.Settings.version)
                Spacer()
                Text(CatchStrings.Settings.versionDisplay(
                    settingsService.appVersion(),
                    settingsService.buildNumber()
                ))
                .foregroundStyle(CatchTheme.textSecondary)
            }

            Text(CatchStrings.Settings.madeWith)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
        } header: {
            Text(CatchStrings.Settings.aboutSection)
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section {
            if authService.authState.isSignedIn {
                Button {
                    isShowingSignOutConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text(CatchStrings.Settings.signOut)
                    }
                    .foregroundStyle(CatchTheme.primary)
                }

                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(CatchStrings.Settings.deleteAccount)
                    }
                }
            } else {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(CatchStrings.Settings.deleteAccount)
                    }
                }
            }
        } header: {
            Text(CatchStrings.Settings.dangerZoneSection)
        }
    }

    // MARK: - Debug

    #if DEBUG
    @AppStorage(AppStorageKeys.hasCompletedUnifiedOnboarding) private var hasCompletedUnifiedOnboarding = true
    @AppStorage(AppStorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = true
    @AppStorage(AppStorageKeys.hasCompletedProfileSetup) private var hasCompletedProfileSetupDebug = true

    private var debugSection: some View {
        Section {
            Button {
                hasCompletedUnifiedOnboarding = false
                hasCompletedOnboarding = false
                hasCompletedProfileSetupDebug = false
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text(CatchStrings.Settings.debugResetOnboarding)
                }
            }
            Button {
                hasCompletedUnifiedOnboarding = false
                hasCompletedOnboarding = false
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text(CatchStrings.Settings.debugResetPostAuth)
                }
            }
        } header: {
            Text(CatchStrings.Settings.debugSection)
        } footer: {
            Text(CatchStrings.Settings.debugFooter)
        }
    }
    #endif

    // MARK: - Actions

    private func performSignOut() {
        Task {
            await authService.signOut()
            RemoteImageCache.shared.removeAll()
            hasCompletedProfileSetup = false
            dismiss()
        }
    }

    private func deleteAccount() {
        let userID = authService.authState.user?.id
        Task {
            await authService.signOut()
            RemoteImageCache.shared.removeAll()
            hasCompletedProfileSetup = false
            dismiss()
            if let userID {
                try? await profileSyncService.deleteProfile(userID: userID)
            }
        }
    }
}
