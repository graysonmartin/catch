import SwiftUI
import CatchCore

struct NotificationsView: View {
    @Environment(SupabaseInAppNotificationService.self) private var notificationService
    @EnvironmentObject private var appRouter: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                        handleTap(item)
                    } label: {
                        NotificationRowView(item: item)
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

    private func handleTap(_ item: NotificationItem) {
        Task {
            await notificationService.markAsRead(notificationId: item.id)
        }
        dismiss()

        switch item.notificationType {
        case .encounterLiked, .encounterCommented:
            if let encounterId = item.encounterId {
                appRouter.navigate(to: .encounter(id: encounterId))
            }
        case .newFollower:
            if let actorId = item.actorId {
                appRouter.navigate(to: .profile(id: actorId))
            }
        }
    }
}
