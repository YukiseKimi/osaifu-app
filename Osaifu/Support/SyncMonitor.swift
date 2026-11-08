import SwiftUI
import SwiftData
import OsaifuCore

/// Holds what the app can say about sync, and reads it again when the app
/// comes forward.
@MainActor
@Observable
final class SyncMonitor {
    private(set) var account: CloudAccount = .unknown
    private(set) var lastChange: Date?

    /// False until the first read finishes. Only then does `.unknown` mean
    /// that iCloud was asked and would not say, rather than "not asked yet".
    private(set) var hasChecked = false

    /// True only while the first read is still out.
    var isConnecting: Bool { !hasChecked }

    /// What the rows and the badge say about the account.
    var title: LocalizedStringKey {
        if isConnecting { return "Connecting…" }
        switch account {
        case .available: return "Up to date"
        case .restricted: return "Not allowed"
        case .noAccount, .unknown: return "Not connected"
        }
    }

    /// The app says "this device only" once it knows, and never before.
    var showsNotice: Bool { hasChecked && !account.syncs }

    func refresh(context: ModelContext) async {
        account = await SyncStatus.account()
        hasChecked = true
        lastChange = try? SyncStatus.lastChange(in: context)
    }
}
