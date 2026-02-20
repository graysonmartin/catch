import CloudKit

extension CKFriendService {

    /// Registers a push subscription for incoming friend requests.
    /// Silently fails if push entitlements are not configured.
    func registerForIncomingRequestNotifications(userID: String) async {
        let predicate = NSPredicate(format: "receiverID == %@", userID)
        let subscriptionID = "incoming-friend-requests-\(userID)"
        let subscription = CKQuerySubscription(
            recordType: "FriendRequest",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        do {
            _ = try await CKContainer(
                identifier: "iCloud.com.catch.catch"
            ).publicCloudDatabase.save(subscription)
        } catch {
            // Push subscriptions require entitlements from a paid dev account.
            // Silently fail until that's configured.
        }
    }
}
