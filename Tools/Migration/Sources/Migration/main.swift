import Foundation
import MigrationLib

/// Beta tester data migration: CloudKit to Supabase
///
/// Usage:
///   swift run Migration \
///     --mapping-file ./user_mapping.json \
///     --export-file ./cloudkit_export.json \
///     --supabase-url https://xxx.supabase.co \
///     --supabase-service-key <service_role_key> \
///     [--dry-run]

let args = CommandLine.arguments

var mappingFile: String?
var exportFile: String?
var supabaseURLString: String?
var supabaseServiceKey: String?
var isDryRun = false

var argIndex = 1
while argIndex < args.count {
    switch args[argIndex] {
    case "--mapping-file":
        argIndex += 1
        if argIndex < args.count { mappingFile = args[argIndex] }
    case "--export-file":
        argIndex += 1
        if argIndex < args.count { exportFile = args[argIndex] }
    case "--supabase-url":
        argIndex += 1
        if argIndex < args.count { supabaseURLString = args[argIndex] }
    case "--supabase-service-key":
        argIndex += 1
        if argIndex < args.count { supabaseServiceKey = args[argIndex] }
    case "--dry-run":
        isDryRun = true
    case "--help", "-h":
        print("""
        Usage: Migration \\
          --mapping-file <path>          JSON file mapping Apple IDs to Supabase UUIDs
          --export-file <path>           JSON file with CloudKit export data
          --supabase-url <url>           Supabase project URL
          --supabase-service-key <key>   Supabase service_role key (NOT anon key)
          [--dry-run]                    Preview migration without writing data
        """)
        exit(0)
    default:
        MigrationLogger.error("Unknown argument: \(args[argIndex])")
        exit(1)
    }
    argIndex += 1
}

guard let mappingFilePath = mappingFile,
      let exportFilePath = exportFile,
      let urlString = supabaseURLString,
      let serviceKey = supabaseServiceKey,
      let url = URL(string: urlString) else {
    MigrationLogger.error("Missing required arguments. Use --help for usage.")
    exit(1)
}

MigrationLogger.info("Starting CloudKit -> Supabase migration")
if isDryRun {
    MigrationLogger.info("[dry-run mode] No data will be written to Supabase.")
}
MigrationLogger.info("Supabase URL: \(urlString)")
MigrationLogger.info("Mapping file: \(mappingFilePath)")
MigrationLogger.info("Export file: \(exportFilePath)")

let runner = MigrationRunner(
    supabaseURL: url,
    supabaseServiceKey: serviceKey,
    isDryRun: isDryRun
)

let semaphore = DispatchSemaphore(value: 0)
var migrationError: Error?

Task {
    do {
        try await runner.run(
            mappingFilePath: mappingFilePath,
            exportFilePath: exportFilePath
        )
    } catch {
        migrationError = error
    }
    semaphore.signal()
}

semaphore.wait()

if let error = migrationError {
    MigrationLogger.error("Migration failed: \(error.localizedDescription)")
    exit(1)
}
