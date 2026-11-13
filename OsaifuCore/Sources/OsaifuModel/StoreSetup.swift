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

    /// The store the app has not prepared yet, so an extension must leave it
    /// alone. The widget shows nothing, and the intent says this.
    public struct NotReady: LocalizedError {
        public let reason: String

        public init(reason: String) {
            self.reason = reason
        }

        public var errorDescription: String? {
            "Open Osaifu on this device once, and this will work."
        }

        public var failureReason: String? { reason }
    }

    /// The one container this process opens, made the first time it is asked
    /// for.
    ///
    /// Opening a container is not cheap: it checks the schema version and may
    /// take a backup. A widget timeline and a Siri intent each used to do all
    /// of that on every run.
    ///
    /// Only a success is kept. A failure that is remembered outlives what
    /// caused it: one locked store while the app migrated used to leave a Siri
    /// intent refusing every expense for as long as its process lived.
    @MainActor
    private static var opened: ModelContainer?

    /// The store an extension reads: a widget, a complication, an App Intent.
    /// An app opens the store itself, with `makeContainer()`.
    ///
    /// An extension never makes the store and never migrates it. Both belong
    /// to the app:
    ///
    /// - A widget that finds no store in the App Group and makes an empty one
    ///   there leaves the app's real store orphaned for good, because the copy
    ///   into the group only ever runs while the group holds no store. The
    ///   user would open the app after an update to find every expense gone,
    ///   with the old store still on the disk and nothing to read it.
    /// - A migration is minutes of work on a large store, and a widget has
    ///   seconds and a few megabytes. A figure that is one version old, or no
    ///   figure at all, is better than a store half moved.
    @MainActor
    public static func sharedContainer() throws -> ModelContainer {
        if let opened { return opened }
        let store = try extensionContainer()
        opened = store
        return store
    }

    /// The store as it already stands in the App Group, or `NotReady`.
    static func extensionContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OsaifuSchemaV4.self)
        guard canUseAppGroup(appGroupID) else {
            throw NotReady(reason: "this process cannot reach the App Group")
        }
        let shared = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: .automatic
        )
        guard extensionMayOpen(
            storeExists: FileManager.default.fileExists(atPath: shared.url.path),
            lastOpenedVersion: sharedDefaults.string(forKey: storeVersionKey)
        ) else {
            throw NotReady(reason: "the app has not opened the store with this build yet")
        }
        // No migration plan: this store is already at this build's version,
        // and if it somehow is not, failing here is the point.
        return try ModelContainer(for: schema, configurations: shared)
    }

    /// Whether an extension may open the shared store: the store must be
    /// there, and the app must have opened it with this build already.
    static func extensionMayOpen(storeExists: Bool, lastOpenedVersion: String?) -> Bool {
        storeExists && !migrationIsExpected(lastOpenedVersion: lastOpenedVersion)
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
            sharedDefaults.set(currentSchemaVersion, forKey: storeVersionKey)
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

    /// The defaults that every Osaifu process reads: the App Group's, because
    /// the store is the App Group's too.
    ///
    /// `UserDefaults.standard` is a different place in each one of them. The
    /// version of the store was kept there, so the app would migrate the
    /// store, write "4.0.0" into its own defaults, and the widget, the
    /// complication and the watch would each still believe a migration was
    /// due and copy the whole store, one by one, inside their own tiny
    /// budgets.
    ///
    /// It falls back to this process's own defaults wherever the group is out
    /// of reach, because the store is then this process's own too: a suite for
    /// a group this process is not entitled to reads back empty every time,
    /// which would have the app believe a migration was due on every launch
    /// and copy the store before each one.
    static var sharedDefaults: UserDefaults {
        guard canUseAppGroup(appGroupID), let shared = UserDefaults(suiteName: appGroupID) else {
            return .standard
        }
        return shared
    }

    /// True when the store was last opened by a build that knew another schema,
    /// which is when SwiftData runs a migration. It is also true on the first
    /// launch of this build for an older store, which never wrote the key.
    public static func migrationIsExpected() -> Bool {
        migrationIsExpected(lastOpenedVersion: sharedDefaults.string(forKey: storeVersionKey))
    }

    static func migrationIsExpected(lastOpenedVersion: String?) -> Bool {
        lastOpenedVersion != currentSchemaVersion
    }

    /// True when this process may read the group container: false on a device
    /// that was never provisioned for the group.
    ///
    /// It is true on the Mac outside a sandbox, a `swift test` run included,
    /// where Foundation hands back a path under `~/Library/Group Containers`
    /// and asks nobody. So this answers "is the group reachable", never "is
    /// this a test".
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

    /// A store of this run's own, in a temporary folder, with no iCloud.
    ///
    /// This is the seam a UI test needs: the app opens a real store, with the
    /// real schema and the real migrations, but not the one a person keeps.
    /// It survives a relaunch, so a journey can check that what it saved is
    /// still there, and `resetting` empties it at the start of a run.
    public static func makeSealedContainer(resetting: Bool) throws -> ModelContainer {
        let folder = URL.temporaryDirectory.appending(path: "OsaifuSealedStore", directoryHint: .isDirectory)
        let files = FileManager.default
        if resetting, files.fileExists(atPath: folder.path) {
            try? files.removeItem(at: folder)
        }
        try files.createDirectory(at: folder, withIntermediateDirectories: true)

        let schema = Schema(versionedSchema: OsaifuSchemaV4.self)
        return try ModelContainer(
            for: schema,
            migrationPlan: OsaifuMigrationPlan.self,
            configurations: ModelConfiguration(
                schema: schema,
                url: folder.appending(path: "sealed.store"),
                cloudKitDatabase: .none
            )
        )
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

