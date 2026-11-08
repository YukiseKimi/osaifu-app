import Foundation
import SwiftData

/// Opens the one store that every Osaifu app shares, and keeps a copy of it
/// before a migration runs.
public enum StoreSetup {

    /// The CloudKit container that holds the private database. Every target
    /// names this one, so each device reads the same records.
    public static let cloudContainerID = "iCloud.com.satsurakyno.MyApp"

    /// The App Group that the app and its extensions share on one device.
    public static let appGroupID = "group.com.satsurakyno.MyApp"

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
        let schema = Schema(versionedSchema: OsaifuSchemaV3.self)
        let ownToTheApp = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private(cloudContainerID)
        )

        // SwiftData calls fatalError when a group is named that the app is not
        // entitled to, so ask first. A catch cannot save the app from that.
        let configuration: ModelConfiguration
        if canUseAppGroup(appGroupID) {
            let shared = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .private(cloudContainerID)
            )
            // The group gives the store a new place. This carries the old store
            // across, once, the first time the app runs with the group.
            try? copyStoreIfNeeded(from: ownToTheApp.url, to: shared.url)
            configuration = shared
        } else {
            configuration = ownToTheApp
        }

        let backup = try? backUpStore(at: configuration.url)
        do {
            return try container(schema: schema, configuration: configuration)
        } catch {
            throw Failure(underlying: error, backupURL: backup)
        }
    }

    /// True when this app may read the group container. It is false in a test
    /// process, and on a device that was never provisioned for the group.
    public static func canUseAppGroup(_ identifier: String) -> Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) != nil
    }

    private static func container(schema: Schema, configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: OsaifuMigrationPlan.self,
            configurations: configuration
        )
    }

    /// Copies a store, and the two SQLite files beside it, into a new place.
    ///
    /// It does nothing when the new place already holds a store, so it runs
    /// once. A copy that fails part way leaves nothing behind, and the old
    /// store stays where it is.
    @discardableResult
    public static func copyStoreIfNeeded(from old: URL, to new: URL) throws -> Bool {
        let files = FileManager.default
        guard old != new,
              files.fileExists(atPath: old.path),
              !files.fileExists(atPath: new.path)
        else { return false }

        try files.createDirectory(at: new.deletingLastPathComponent(), withIntermediateDirectories: true)

        var written: [URL] = []
        do {
            for suffix in ["", "-wal", "-shm"] {
                let source = URL(filePath: old.path + suffix)
                guard files.fileExists(atPath: source.path) else { continue }
                let target = URL(filePath: new.path + suffix)
                try files.copyItem(at: source, to: target)
                written.append(target)
            }
        } catch {
            for file in written { try? files.removeItem(at: file) }
            throw error
        }
        return true
    }

    /// A store that lives in memory, for previews and tests.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OsaifuSchemaV3.self)
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

