import Foundation
import SwiftData

/// Opens the one store that every Osaifu app shares, and keeps a copy of it
/// before a migration runs.
public enum StoreSetup {

    /// The CloudKit container that holds the private database. The
    /// entitlements of each target name it, and SyncStatus asks it for the
    /// account state.
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

    /// The one container this process opens, made the first time it is asked
    /// for.
    ///
    /// Opening a container is not cheap: it checks the schema version, may
    /// copy the store into the App Group and may take a backup. A widget
    /// timeline and a Siri intent each used to do all of that on every run.
    @MainActor
    private static var opened: Result<ModelContainer, any Error>?

    /// The live store, opened once per process.
    ///
    /// Call this from anything that runs more than once: a widget provider,
    /// an App Intent. An app that opens the store at launch and keeps it can
    /// call `makeContainer()` directly.
    @MainActor
    public static func sharedContainer() throws -> ModelContainer {
        if let opened { return try opened.get() }
        let result = Result { try makeContainer() }
        opened = result
        return try result.get()
    }

    /// The live store, with iCloud mirroring and the migration plan.
    ///
    /// The configuration carries no URL, so SwiftData picks its own default
    /// location, and the backup reads that same location back from it.
    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OsaifuSchemaV4.self)
        // Automatic, rather than naming the container outright: SwiftData
        // takes the one container in the entitlements, and mirrors nothing
        // when there are none. Naming it makes a build with no iCloud
        // entitlement die on launch, which is every unsigned build.
        let ownToTheApp = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        // SwiftData calls fatalError when a group is named that the app is not
        // entitled to, so ask first. A catch cannot save the app from that.
        var configuration = ownToTheApp
        if canUseAppGroup(appGroupID) {
            let shared = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(appGroupID),
                cloudKitDatabase: .automatic
            )
            do {
                // The group gives the store a new place. This carries the old
                // store across, once, the first time the app runs with it.
                try copyStoreIfNeeded(from: ownToTheApp.url, to: shared.url)
                configuration = shared
            } catch {
                // The copy failed, so the group holds no store, or part of one.
                // Keep reading the store that certainly holds the expenses.
                configuration = ownToTheApp
            }
        }

        // A copy of the store is worth its disk only when a migration is about
        // to run. Every other launch opens the store as it is.
        let backup = migrationIsExpected() ? try? backUpStore(at: configuration.url) : nil
        do {
            let store = try container(schema: schema, configuration: configuration)
            UserDefaults.standard.set(currentSchemaVersion, forKey: storeVersionKey)
            return store
        } catch {
            throw Failure(underlying: error, backupURL: backup)
        }
    }

    /// The schema this build knows, as "3.0.0".
    public static var currentSchemaVersion: String {
        let version = OsaifuSchemaV4.versionIdentifier
        return "\(version.major).\(version.minor).\(version.patch)"
    }

    static let storeVersionKey = "OsaifuStoreSchemaVersion"

    /// True when the store was last opened by a build that knew another schema,
    /// which is when SwiftData runs a migration. It is also true on the first
    /// launch of this build for an older store, which never wrote the key.
    public static func migrationIsExpected() -> Bool {
        migrationIsExpected(lastOpenedVersion: UserDefaults.standard.string(forKey: storeVersionKey))
    }

    static func migrationIsExpected(lastOpenedVersion: String?) -> Bool {
        lastOpenedVersion != currentSchemaVersion
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

    /// The store, and the two files SQLite keeps beside it.
    static let storeFileSuffixes = ["", "-wal", "-shm"]

    /// Copies a store and its two SQLite files into a new place.
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

        try copyStoreFiles(from: old, to: new, replacing: false)
        return true
    }

    /// Copies the store and its sidecars, and removes what it wrote if any one
    /// of them fails, so a half copy never stands in for a store.
    static func copyStoreFiles(from old: URL, to new: URL, replacing: Bool) throws {
        let files = FileManager.default
        try files.createDirectory(at: new.deletingLastPathComponent(), withIntermediateDirectories: true)

        var written: [URL] = []
        do {
            for suffix in storeFileSuffixes {
                let source = URL(filePath: old.path + suffix)
                guard files.fileExists(atPath: source.path) else { continue }
                let target = URL(filePath: new.path + suffix)
                if replacing, files.fileExists(atPath: target.path) {
                    try files.removeItem(at: target)
                }
                try files.copyItem(at: source, to: target)
                written.append(target)
            }
        } catch {
            for file in written { try? files.removeItem(at: file) }
            throw error
        }
    }

    /// A store that lives in memory, for previews and tests.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OsaifuSchemaV4.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    /// Copies the store, and the two SQLite files beside it, under `Backups`.
    /// Returns the copy, or nil when there is no store yet.
    ///
    /// The `-wal` file holds transactions that SQLite has not written into the
    /// store itself, so a copy of the store alone can be missing the newest
    /// expenses.
    @discardableResult
    public static func backUpStore(at url: URL, keeping: Int = 3) throws -> URL? {
        let files = FileManager.default
        guard files.fileExists(atPath: url.path) else { return nil }

        let folder = url.deletingLastPathComponent().appending(path: "Backups")
        try files.createDirectory(at: folder, withIntermediateDirectories: true)

        let stamp = Date.now.formatted(
            .iso8601
            .dateSeparator(.omitted)
            .timeSeparator(.omitted)
        )
        let name = url.deletingPathExtension().lastPathComponent
        let copy = folder.appending(path: "\(name)-\(stamp).\(url.pathExtension)")
        try copyStoreFiles(from: url, to: copy, replacing: true)
        try? pruneBackups(in: folder, matching: name, keeping: keeping)
        return copy
    }

    /// Deletes all but the newest `keeping` backups, so the folder cannot grow
    /// without end.
    static func pruneBackups(in folder: URL, matching name: String, keeping: Int) throws {
        let files = FileManager.default
        let all = try files.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.lastPathComponent.hasPrefix("\(name)-") && $0.pathExtension == "store" }
            .sorted { left, right in
                let a = (try? left.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let b = (try? right.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return a > b
            }
        for old in all.dropFirst(max(0, keeping)) {
            for suffix in storeFileSuffixes {
                try? files.removeItem(at: URL(filePath: old.path + suffix))
            }
        }
    }
}

