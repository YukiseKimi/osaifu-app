import SwiftUI
import OsaifuCore

/// One small symbol that says where the data stands with iCloud. It sits in
/// the toolbar of This Month and beside the Sync row in Settings, so the user
/// can see the state at any time.
struct SyncBadge: View {
    let account: CloudAccount

    private var symbol: String {
        switch account {
        case .available: "checkmark.icloud.fill"
        case .unknown: "arrow.clockwise.icloud.fill"
        case .noAccount, .restricted: "icloud.slash.fill"
        }
    }

    private var tint: Color {
        switch account {
        case .available: .green
        case .unknown: .secondary
        case .noAccount, .restricted: .orange
        }
    }

    private var label: LocalizedStringKey {
        switch account {
        case .available: "iCloud: connected"
        case .unknown: "iCloud: connecting"
        case .noAccount: "iCloud: not connected"
        case .restricted: "iCloud: not allowed"
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.footnote)
            .foregroundStyle(tint)
            .symbolEffect(.pulse, isActive: account == .unknown)
            .accessibilityLabel(label)
    }
}

/// The one line that This Month shows while iCloud cannot carry the expenses.
struct SyncNotice: View {
    let account: CloudAccount

    var body: some View {
        if !account.syncs && account != .unknown {
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
        ForEach([CloudAccount.available, .unknown, .noAccount, .restricted], id: \.self) { account in
            HStack { SyncBadge(account: account); Text(String(describing: account)) }
        }
        SyncNotice(account: .noAccount)
    }
    .padding()
}
