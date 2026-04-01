import SwiftUI
import CatchCore

struct NotificationsView: View {
    @Environment(SupabaseInAppNotificationService.self) private var notificationService
    @Environment(\.dismiss) private var dismiss

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if notificationService.isLoading && !notificationService.hasLoaded {
                    PawLoadingView()
                } else if notificationService.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: CatchStrings.Notifications.emptyTitle,
                        subtitle: CatchStrings.Notifications.emptySubtitle
                    )
                } else {
                    notificationList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CatchTheme.background)
            .navigationTitle(CatchStrings.Notifications.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(CatchStrings.Common.done) {
                        dismiss()
                    }
                    .foregroundStyle(CatchTheme.primary)
                }
            }
            .navigationDestination(for: RemoteProfileRoute.self) { route in
                RemoteProfileContent(
                    userID: route.userID,
                    initialDisplayName: route.displayName
                )
            }
            .navigationDestination(for: EncounterRoute.self) { route in
                EncounterDetailLoadingView(encounterID: route.encounterID)
            }
            .refreshable {
                await notificationService.refresh()
            }
            .task {
                await notificationService.loadIfNeeded()
                await notificationService.markAllAsRead()
            }
        }
    }

    // MARK: - List

    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notificationService.notifications) { item in
                    Button {
                        handleEncounterTap(item)
                    } label: {
                        NotificationRowView(item: item) {
                            handleAvatarTap(item)
                        }
                    }
                    .buttonStyle(.plain)

                    if item.id != notificationService.notifications.last?.id {
                        Divider()
                            .padding(.leading, CatchSpacing.space16 + 40 + CatchSpacing.space10)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func handleEncounterTap(_ item: NotificationItem) {
        Task {
            await notificationService.markAsRead(notificationId: item.id)
        }

        switch item.notificationType {
        case .encounterLiked, .encounterCommented:
            if let encounterId = item.encounterId {
                navigationPath.append(EncounterRoute(encounterID: encounterId))
            }
        case .newFollower:
            if let actorId = item.actorId {
                navigationPath.append(RemoteProfileRoute(
                    userID: actorId,
                    displayName: item.actorDisplayName
                ))
            }
        }
    }

    private func handleAvatarTap(_ item: NotificationItem) {
        guard let userID = item.actorUserID, !userID.isEmpty else {
            handleEncounterTap(item)
            return
        }
        Task {
            await notificationService.markAsRead(notificationId: item.id)
        }
        navigationPath.append(RemoteProfileRoute(
            userID: userID,
            displayName: item.actorDisplayName
        ))
    }
}
