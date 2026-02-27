import CloudKit

public extension CKFollowService {
    func registerForFollowNotifications(userID: String) {
        let predicate = NSPredicate(format: "followeeID == %@", userID)
        let subscription = CKQuerySubscription(
            recordType: "Follow",
            predicate: predicate,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        let container = CKContainer(identifier: "iCloud.com.catch.catch")
        container.publicCloudDatabase.save(subscription) { _, _ in }
    }
}
