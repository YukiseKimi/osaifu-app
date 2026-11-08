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
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
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
    }
}

#Preview {
    RootView()
        .modelContainer(for: Expense.self, inMemory: true)
}
