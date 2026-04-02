import SwiftUI
import UserNotifications
import CatchCore

/// Notification permissions step of the new-user walkthrough.
struct WalkthroughNotificationStep: View {
    @State private var manager = OnboardingNotificationManager()

    var body: some View {
        VStack(spacing: CatchSpacing.space24) {
            Spacer()

            iconSection

            textSection

            permissionButton

            Spacer()
            Spacer()
        }
        .padding(.horizontal, CatchSpacing.space32)
    }

    // MARK: - Subviews

    private var iconSection: some View {
        Image(systemName: "bell.badge.fill")
            .font(.system(size: 72))
            .foregroundStyle(CatchTheme.primary)
    }

    private var textSection: some View {
        VStack(spacing: CatchSpacing.space12) {
            Text(CatchStrings.Walkthrough.notificationTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CatchTheme.textPrimary)

            Text(CatchStrings.Walkthrough.notificationSubtitle)
                .font(.subheadline)
                .foregroundStyle(CatchTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)

            Text(CatchStrings.Walkthrough.notificationReassurance)
                .font(.caption)
                .foregroundStyle(CatchTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(CatchSpacing.space4)
                .padding(.top, CatchSpacing.space4)
        }
    }

    @ViewBuilder
    private var permissionButton: some View {
        if !manager.hasRequested {
            Button {
                Task { await manager.requestPermission() }
            } label: {
                HStack {
                    Image(systemName: "bell.fill")
                    Text(CatchStrings.Walkthrough.enableNotifications)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CatchTheme.primary)
                .padding(.horizontal, CatchSpacing.space20)
                .padding(.vertical, CatchSpacing.space10)
                .background(CatchTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        } else {
            HStack(spacing: CatchSpacing.space6) {
                Image(systemName: manager.wasGranted ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(manager.wasGranted ? .green : CatchTheme.textSecondary)
                Text(manager.wasGranted
                     ? CatchStrings.Walkthrough.notificationEnabled
                     : CatchStrings.Walkthrough.notificationSkipped)
                    .font(.caption)
                    .foregroundStyle(CatchTheme.textSecondary)
            }
        }
    }
}

// MARK: - Permission Manager

@Observable
private final class OnboardingNotificationManager {
    var hasRequested = false
    var wasGranted = false

    private let center = UNUserNotificationCenter.current()

    @MainActor
    init() {
        Task { await checkCurrentStatus() }
    }

    private func checkCurrentStatus() async {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus != .notDetermined {
            hasRequested = true
            wasGranted = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
        }
    }

    @MainActor
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            hasRequested = true
            wasGranted = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            hasRequested = true
            wasGranted = false
        }
    }
}
