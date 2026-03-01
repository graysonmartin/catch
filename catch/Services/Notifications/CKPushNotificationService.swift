import CloudKit
import CatchCore
import UserNotifications
import Observation

@Observable
@MainActor
final class CKPushNotificationService: PushNotificationService {
    private static let containerID = "iCloud.com.catch.catch"

    private(set) var isRegistered = false

    private var database: CKDatabase {
        CKContainer(identifier: Self.containerID).publicCloudDatabase
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        isRegistered = granted
        return granted
    }

    // MARK: - Subscription Management

    func setupSubscriptions(for ownerID: String) async throws {
        let existing = try await fetchExistingSubscriptionIDs()
        let desired = desiredSubscriptionIDs(for: ownerID)

        let toCreate = desired.subtracting(existing)
        let toRemove = existing.filter { id in
            isAppManagedSubscription(id) && !desired.contains(id)
        }

        for id in toRemove {
            try await removeSubscription(id: id)
        }

        for id in toCreate {
            try await createSubscription(id: id, ownerID: ownerID)
        }
    }

    func removeAllSubscriptions() async throws {
        let existing = try await fetchExistingSubscriptionIDs()
        let appManaged = existing.filter { isAppManagedSubscription($0) }

        for id in appManaged {
            try await removeSubscription(id: id)
        }
    }

    // MARK: - Notification Handling

    func handleNotification(userInfo: [String: Any]) async {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              let subscriptionID = notification.subscriptionID else {
            return
        }

        guard let eventType = NotificationPayload.eventType(for: subscriptionID) else {
            return
        }

        let payload = NotificationPayload(
            eventType: eventType,
            subscriptionID: subscriptionID
        )

        await presentLocalNotification(for: payload)
    }

    // MARK: - Private Helpers

    private func desiredSubscriptionIDs(for ownerID: String) -> Set<String> {
        [
            NotificationPayload.encounterSubscriptionID(for: ownerID),
            NotificationPayload.likeSubscriptionID(for: ownerID),
            NotificationPayload.commentSubscriptionID(for: ownerID)
        ]
    }

    private func isAppManagedSubscription(_ id: String) -> Bool {
        id.hasPrefix(NotificationPayload.encounterSubscriptionPrefix)
            || id.hasPrefix(NotificationPayload.likeSubscriptionPrefix)
            || id.hasPrefix(NotificationPayload.commentSubscriptionPrefix)
    }

    private func fetchExistingSubscriptionIDs() async throws -> Set<String> {
        do {
            let subscriptions = try await database.allSubscriptions()
            return Set(subscriptions.map(\.subscriptionID))
        } catch {
            throw PushNotificationError.fetchSubscriptionsFailed
        }
    }

    private func removeSubscription(id: String) async throws {
        try await database.deleteSubscription(withID: id)
    }

    private func createSubscription(id: String, ownerID: String) async throws {
        let subscription: CKQuerySubscription

        if id.hasPrefix(NotificationPayload.encounterSubscriptionPrefix) {
            subscription = encounterSubscription(id: id, ownerID: ownerID)
        } else if id.hasPrefix(NotificationPayload.likeSubscriptionPrefix) {
            subscription = likeSubscription(id: id, ownerID: ownerID)
        } else if id.hasPrefix(NotificationPayload.commentSubscriptionPrefix) {
            subscription = commentSubscription(id: id, ownerID: ownerID)
        } else {
            return
        }

        do {
            _ = try await database.save(subscription)
        } catch {
            throw PushNotificationError.subscriptionFailed
        }
    }

    private func encounterSubscription(id: String, ownerID: String) -> CKQuerySubscription {
        let predicate = NSPredicate(format: "ownerID == %@", ownerID)
        let subscription = CKQuerySubscription(
            recordType: EncounterRecordMapper.recordType,
            predicate: predicate,
            subscriptionID: id,
            options: [.firesOnRecordCreation]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        return subscription
    }

    private func likeSubscription(id: String, ownerID: String) -> CKQuerySubscription {
        let predicate = NSPredicate(format: "encounterOwnerID == %@", ownerID)
        let subscription = CKQuerySubscription(
            recordType: LikeRecordMapper.recordType,
            predicate: predicate,
            subscriptionID: id,
            options: [.firesOnRecordCreation]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        return subscription
    }

    private func commentSubscription(id: String, ownerID: String) -> CKQuerySubscription {
        let predicate = NSPredicate(format: "encounterOwnerID == %@", ownerID)
        let subscription = CKQuerySubscription(
            recordType: CommentRecordMapper.recordType,
            predicate: predicate,
            subscriptionID: id,
            options: [.firesOnRecordCreation]
        )
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        return subscription
    }

    private func presentLocalNotification(for payload: NotificationPayload) async {
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch payload.eventType {
        case .newEncounter:
            content.title = CatchStrings.Notifications.encounterAlertTitle
            content.body = CatchStrings.Notifications.encounterAlertBody
        case .encounterLiked:
            content.title = CatchStrings.Notifications.likeAlertTitle
            content.body = CatchStrings.Notifications.likeAlertBody
        case .encounterCommented:
            content.title = CatchStrings.Notifications.commentAlertTitle
            content.body = CatchStrings.Notifications.commentAlertBody
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
