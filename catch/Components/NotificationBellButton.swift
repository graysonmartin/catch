import SwiftUI

private enum Layout {
    static let badgeSize: CGFloat = 16
    static let badgeFontSize: CGFloat = 10
    static let badgeOffset: CGFloat = -6
}

struct NotificationBellButton: View {
    @Environment(SupabaseInAppNotificationService.self) private var notificationService
    @State private var isShowingNotifications = false

    var body: some View {
        Button {
            isShowingNotifications = true
        } label: {
            bellIcon
        }
        .sheet(isPresented: $isShowingNotifications) {
            NotificationsView()
        }
    }

    // MARK: - Bell Icon

    private var bellIcon: some View {
        Image(systemName: "bell.fill")
            .foregroundStyle(CatchTheme.primary)
            .overlay(alignment: .topTrailing) {
                badge
            }
    }

    @ViewBuilder
    private var badge: some View {
        let count = notificationService.unreadCount
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.system(size: Layout.badgeFontSize, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, CatchSpacing.space4)
                .frame(minWidth: Layout.badgeSize, minHeight: Layout.badgeSize)
                .background(Color.red)
                .clipShape(Capsule())
                .offset(x: Layout.badgeOffset, y: Layout.badgeOffset)
        }
    }
}
