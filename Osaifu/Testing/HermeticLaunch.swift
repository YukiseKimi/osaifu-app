import Foundation
import OsaifuModel
import OsaifuSync
import SwiftData

/// The one place a launch decides which store the app opens.
///
/// A journey must not write into the store a person keeps, and must not
/// depend on what is already in it. A sealed launch opens a store of the
/// run's own in a temporary folder, with no iCloud behind it.
///
/// This is built in every configuration, never inside `#if DEBUG`: a Release
/// build that leaves the code out breaks the archive while every Debug lane
/// is green. The build setting decides instead. `OSAIFU_SEALED_LAUNCH` is YES
/// for Debug and NO for Release, the Info.plist carries it, and a Release app
/// therefore ignores every flag below and opens the live store.
enum HermeticLaunch {

    /// True when this build is allowed to seal a launch at all.
    static var isAllowed: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OsaifuSealedLaunch") as? String == "YES"
    }

    /// The store this launch should open.
    static func container(arguments: [String] = CommandLine.arguments) throws -> ModelContainer {
        guard isAllowed else { return try StoreSetup.makeContainer() }

        let flags = arguments.filter { $0.hasPrefix("--") }
        for flag in flags where !LaunchFlag.isKnown(flag) {
            fatalError("Unknown launch flag \(flag). Add it to LaunchFlag, or fix the spelling.")
        }
        guard flags.contains(LaunchFlag.sealed.rawValue) else {
            return try StoreSetup.makeContainer()
        }

        // WidgetKit is an outside system. A journey must not wake a widget
        // extension, which has its own process and its own store.
        WidgetRefresh.use {}

        return try StoreSetup.makeSealedContainer(
            resetting: flags.contains(LaunchFlag.reset.rawValue)
        )
    }
}
