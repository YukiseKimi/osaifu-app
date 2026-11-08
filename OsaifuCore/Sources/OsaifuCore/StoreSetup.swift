import Foundation
import SwiftData

/// Opens the one store that every Osaifu app shares, and keeps a copy of it
/// before a migration runs.
public enum StoreSetup {

    /// A migration that did not finish. The store is untouched, and `backupURL`
    /// names the copy, when one could be made.
    public struct Failure: Error {
        public let underlying: any Error
        public let backupURL: URL?

        public init(underlying: any Error, backupURL: URL?) {
            self.underlying = underlying
            self.backupURL = backupURL
        }
    }

    /// The live store, with iCloud mirroring and the migration plan.
    ///
    /// The configuration carries no URL, so SwiftData picks its own default
    /// location, and the backup reads that same location back from it.
    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OsaifuSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        let backup = try? backUpStore(at: configuration.url)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: OsaifuMigrationPlan.self,
                configurations: configuration
            )
        } catch {
            throw Failure(underlying: error, backupURL: backup)
        }
    }

    /// A store that lives in memory, for previews and tests.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OsaifuSchemaV2.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    /// Copies the store beside itself, under `Backups`, and returns the copy.
    /// Returns nil when there is no store yet, which is every first launch.
    @discardableResult
    public static func backUpStore(at url: URL) throws -> URL? {
        let files = FileManager.default
        guard files.fileExists(atPath: url.path) else { return nil }

        let folder = url.deletingLastPathComponent().appending(path: "Backups")
        try files.createDirectory(at: folder, withIntermediateDirectories: true)

        let stamp = Date.now.formatted(
            .iso8601
            .dateSeparator(.omitted)
            .timeSeparator(.omitted)
        )
        let copy = folder.appending(path: "\(url.deletingPathExtension().lastPathComponent)-\(stamp).\(url.pathExtension)")
        if files.fileExists(atPath: copy.path) { try files.removeItem(at: copy) }
        try files.copyItem(at: url, to: copy)
        return copy
    }
}

