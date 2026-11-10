import SwiftUI
import SwiftData

/// Holds what an app can say about sync, and reads it again when the app
/// comes forward.
@MainActor
@Observable
final public class SyncMonitor {
    public init() {}

    public private(set) var account: CloudAccount = .unknown
    public private(set) var lastChange: Date?

    /// False until the first read finishes. Only then does `.unknown` mean
    /// that iCloud was asked and would not say, rather than "not asked yet".
    public private(set) var hasChecked = false

    /// True only while the first read is still out.
    public var isConnecting: Bool { !hasChecked }

    /// What the rows and the badge say about the account.
    public var title: LocalizedStringKey {
        if isConnecting { return "Connecting…" }
        switch account {
        case .available: return "Up to date"
        case .restricted: return "Not allowed"
        case .noAccount, .unknown: return "Not connected"
        }
    }

    /// An app says "this device only" once it knows, and never before.
    public var showsNotice: Bool { hasChecked && !account.syncs }

    public func refresh(context: ModelContext) async {
        account = await SyncStatus.account()
        hasChecked = true
        lastChange = try? SyncStatus.lastChange(in: context)
    }
}
