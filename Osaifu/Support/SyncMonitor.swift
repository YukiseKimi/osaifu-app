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

    /// What the rows and the badge say about the account.
    var title: LocalizedStringKey {
        switch account {
        case .available: "Up to date"
        case .unknown: "Connecting…"
        case .noAccount: "Not connected"
        case .restricted: "Not allowed"
        }
    }

    func refresh(context: ModelContext) async {
        account = await SyncStatus.account()
        lastChange = try? SyncStatus.lastChange(in: context)
    }
}
