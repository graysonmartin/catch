import SwiftUI
import CatchCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel
    @State private var isShowingSignOutConfirm = false

    init(settingsService: any SettingsService, authService: (any AuthService)? = nil) {
        _viewModel = State(initialValue: SettingsViewModel(
            settingsService: settingsService,
            authService: authService
        ))
    }

    var body: some View {
        Form {
            displayNameSection
            notificationsSection
            appearanceSection
            aboutSection

            if viewModel.isSignedIn {
                signOutSection
            }
        }
        .navigationTitle(CatchStrings.Settings.title)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            CatchStrings.Settings.signOutConfirmTitle,
            isPresented: $isShowingSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button(CatchStrings.Settings.signOutConfirm, role: .destructive) {
                viewModel.signOut()
                dismiss()
            }
            Button(CatchStrings.Common.cancel, role: .cancel) { }
        } message: {
            Text(CatchStrings.Settings.signOutConfirmMessage)
        }
    }

    // MARK: - Display Name

    private var displayNameSection: some View {
        Section {
            TextField(
                CatchStrings.Settings.displayNamePlaceholder,
                text: $viewModel.displayName
            )
        } header: {
            Text(CatchStrings.Settings.displayNameSection)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(
                CatchStrings.Settings.notificationsToggle,
                isOn: $viewModel.isNotificationsEnabled
            )
            .tint(CatchTheme.primary)
        } header: {
            Text(CatchStrings.Settings.notificationsSection)
        } footer: {
            Text(CatchStrings.Settings.notificationsFooter)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            Picker(CatchStrings.Settings.appearanceLabel, selection: $viewModel.appearanceMode) {
                Text(CatchStrings.Settings.appearanceSystem)
                    .tag(AppearanceMode.system)
                Text(CatchStrings.Settings.appearanceLight)
                    .tag(AppearanceMode.light)
                Text(CatchStrings.Settings.appearanceDark)
                    .tag(AppearanceMode.dark)
            }
        } header: {
            Text(CatchStrings.Settings.appearanceSection)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text(CatchStrings.Settings.version)
                Spacer()
                Text(viewModel.versionDisplay)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        } header: {
            Text(CatchStrings.Settings.aboutSection)
        } footer: {
            Text(CatchStrings.Settings.madeWithAttitude)
        }
    }

    // MARK: - Sign Out

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                isShowingSignOutConfirm = true
            } label: {
                HStack {
                    Spacer()
                    Text(CatchStrings.Settings.signOut)
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
    }
}
