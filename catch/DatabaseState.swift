import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.catch.app", category: "Database")

@Observable
@MainActor
final class DatabaseState {
    private(set) var status: Status

    enum Status {
        case ready(ModelContainer)
        case failed(String)
    }

    init() {
        status = Self.attemptInit()
    }

    func retry() {
        logger.info("Retrying ModelContainer initialization")
        status = Self.attemptInit()
    }

    func resetAndRetry() {
        logger.warning("Wiping database store and retrying ModelContainer initialization")
        Self.deleteStoreFiles()
        status = Self.attemptInit()
    }

    // MARK: - Private

    private static let schema = Schema(versionedSchema: CatchSchemaV6.self)
    private static let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)

    private static func attemptInit() -> Status {
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: CatchMigrationPlan.self,
                configurations: config
            )
            logger.info("ModelContainer initialized successfully")
            return .ready(container)
        } catch {
            #if DEBUG
            logger.error("ModelContainer init failed (DEBUG), attempting auto-wipe: \(error.localizedDescription, privacy: .public)")
            deleteStoreFiles()
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: CatchMigrationPlan.self,
                    configurations: config
                )
                logger.info("ModelContainer recovered after auto-wipe")
                return .ready(container)
            } catch {
                logger.fault("ModelContainer failed even after auto-wipe: \(error.localizedDescription, privacy: .public)")
                return .failed(error.localizedDescription)
            }
            #else
            logger.fault("ModelContainer init failed in production: \(error.localizedDescription, privacy: .public)")
            return .failed(error.localizedDescription)
            #endif
        }
    }

    private static func deleteStoreFiles() {
        let storeURL = config.url
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = suffix.isEmpty ? storeURL : URL(fileURLWithPath: storeURL.path() + suffix)
            do {
                try fm.removeItem(at: fileURL)
            } catch {
                logger.warning("Failed to remove \(fileURL.lastPathComponent): \(error.localizedDescription, privacy: .public)")
            }
        }
        logger.info("Database store file cleanup completed")
    }
}
