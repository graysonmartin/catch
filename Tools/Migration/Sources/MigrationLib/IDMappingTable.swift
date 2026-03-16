import Foundation

/// Tracks the mapping between CloudKit record names and Supabase UUIDs
/// generated during migration. Used to resolve foreign-key references
/// (e.g., encounter to cat, like to encounter) in subsequent migration steps.
public final class IDMappingTable: Sendable {
    private let catMappings: [String: String]
    private let encounterMappings: [String: String]

    public init(
        catMappings: [String: String] = [:],
        encounterMappings: [String: String] = [:]
    ) {
        self.catMappings = catMappings
        self.encounterMappings = encounterMappings
    }

    /// Looks up the Supabase UUID for a CloudKit cat record name.
    public func supabaseCatID(for cloudKitRecordName: String) throws -> String {
        guard let id = catMappings[cloudKitRecordName] else {
            throw MigrationError.missingCatMapping(cloudKitRecordName: cloudKitRecordName)
        }
        return id
    }

    /// Looks up the Supabase UUID for a CloudKit encounter record name.
    public func supabaseEncounterID(for cloudKitRecordName: String) throws -> String {
        guard let id = encounterMappings[cloudKitRecordName] else {
            throw MigrationError.missingEncounterMapping(cloudKitRecordName: cloudKitRecordName)
        }
        return id
    }

    public var catCount: Int { catMappings.count }
    public var encounterCount: Int { encounterMappings.count }
}

/// Mutable builder for IDMappingTable, used during migration.
public final class IDMappingTableBuilder {
    private var catMappings: [String: String] = [:]
    private var encounterMappings: [String: String] = [:]

    public init() {}

    public func addCatMapping(cloudKitRecordName: String, supabaseID: String) {
        catMappings[cloudKitRecordName] = supabaseID
    }

    public func addEncounterMapping(cloudKitRecordName: String, supabaseID: String) {
        encounterMappings[cloudKitRecordName] = supabaseID
    }

    public func build() -> IDMappingTable {
        IDMappingTable(catMappings: catMappings, encounterMappings: encounterMappings)
    }
}
