import SwiftUI
import OsaifuModel
import OsaifuSync

/// One small symbol that says where the data stands with iCloud. It sits in
/// the toolbar of This Month and beside the Sync row in Settings, so the user
/// can see the state at any time.
public struct SyncBadge: View {
    let account: CloudAccount

    /// True only while the first read is still out. A read that finished and
    /// said nothing is "not connected": the expenses are going nowhere, and
    /// a badge that says "connecting" for ever tells the user nothing.
    var isConnecting: Bool = false

    public init(account: CloudAccount, isConnecting: Bool = false) {
        self.account = account
        self.isConnecting = isConnecting
    }

    private var symbol: String {
        if isConnecting { return "arrow.clockwise.icloud.fill" }
        return account.syncs ? "checkmark.icloud.fill" : "icloud.slash.fill"
    }

    private var tint: Color {
        if isConnecting { return .secondary }
        return account.syncs ? .green : .orange
    }

    private var label: LocalizedStringKey {
        if isConnecting { return "iCloud: connecting" }
        switch account {
        case .available: return "iCloud: connected"
        case .restricted: return "iCloud: not allowed"
        case .noAccount, .unknown: return "iCloud: not connected"
        }
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.footnote)
            .foregroundStyle(tint)
            .symbolEffect(.pulse, isActive: isConnecting)
            .accessibilityLabel(label)
    }
}

/// The one line that This Month shows while iCloud cannot carry the expenses.
public struct SyncNotice: View {
    let account: CloudAccount

    public init(account: CloudAccount) {
        self.account = account
    }

    public var body: some View {
        if !account.syncs {
            HStack(spacing: 8) {
                SyncBadge(account: account)
                Text("This device only. Sign in to iCloud to see these expenses on your other devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HStack { SyncBadge(account: .unknown, isConnecting: true); Text("connecting") }
        ForEach([CloudAccount.available, .unknown, .noAccount, .restricted], id: \.self) { account in
            HStack { SyncBadge(account: account); Text(String(describing: account)) }
        }
        SyncNotice(account: .noAccount)
    }
    .padding()
}
