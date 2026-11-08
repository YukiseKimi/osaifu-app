import SwiftUI
import SwiftData
import OsaifuCore

@main
struct BudgetApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // SwiftData automatically enables iCloud sync when the iCloud/CloudKit
        // capability is present in the project's entitlements.
        .modelContainer(for: Expense.self)
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
