import CloudKit

/// Centralized CloudKit infrastructure. Container ID is defined once here;
/// all services receive a `CKDatabase` through their initializers rather
/// than creating their own.
public enum CloudKitConfiguration {
    public static let containerIdentifier = "iCloud.com.catch.catch"

    public static var publicDatabase: CKDatabase {
        CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }
}
