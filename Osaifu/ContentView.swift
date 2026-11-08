import SwiftUI
import SwiftData
import OsaifuCore

@main
struct OsaifuApp: App {
    /// The store, or the migration failure that stopped it from opening.
    private let store: Result<ModelContainer, any Error>

    init() {
        // StoreSetup copies the store before a migration runs, and mirrors it
        // to iCloud through the CloudKit capability in the entitlements.
        store = Result { try StoreSetup.makeContainer() }
    }

    var body: some Scene {
        WindowGroup {
            switch store {
            case .success(let container):
                RootView()
                    .modelContainer(container)
            case .failure(let error):
                StoreFailureView(error: error)
            }
        }
    }
}

/// The top-level tab interface, shared across iOS and macOS.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [Preferences]
    @Environment(\.scenePhase) private var scenePhase
    @State private var sync = SyncMonitor()
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    /// The newest settings row wins, so two devices agree. Before the first row
    /// exists, the currency the first version of the app displayed wins.
    private var homeCurrencyCode: String {
        let code = preferences.max { $0.updatedAt < $1.updatedAt }?.homeCurrencyCode ?? ""
        return code.isEmpty ? Preferences.legacyCurrencyCode() : code
    }

    var body: some View {
        TabView {
            Tab("Overview", systemImage: "chart.pie.fill") {
                OverviewView()
            }
            Tab("Expenses", systemImage: "list.bullet") {
                ExpensesListView()
            }
            Tab("History", systemImage: "chart.bar.fill") {
                HistoryView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(.appAccent)
        // System follows the device; Light/Dark force a scheme app-wide.
        .preferredColorScheme(appearance.colorScheme)
        .environment(\.homeCurrencyCode, homeCurrencyCode)
        .environment(sync)
        .task {
            // Makes the one settings row, and drops any duplicate that iCloud
            // delivered from another device.
            _ = try? Preferences.current(
                in: modelContext,
                fallbackCurrencyCode: Preferences.legacyCurrencyCode()
            )
            await sync.refresh(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await sync.refresh(context: modelContext) }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: Expense.self, inMemory: true)
}
