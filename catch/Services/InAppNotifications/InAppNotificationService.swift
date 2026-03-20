import Foundation

/// Data-access protocol for in-app notification display.
///
/// Views depend on this protocol rather than the concrete Supabase implementation,
/// enabling testability and swappability.
@MainActor
protocol InAppNotificationService: Observable, Sendable {
    var notifications: [NotificationItem] { get }
    var unreadCount: Int { get }
    var isLoading: Bool { get }
    var hasLoaded: Bool { get }

    func loadIfNeeded() async
    func refresh() async
    func markAsRead(notificationId: String) async
    func markAllAsRead() async
}
