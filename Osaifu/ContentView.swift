import SwiftUI
import SwiftData
import OsaifuModel
import OsaifuUI

@main
struct OsaifuApp: App {
    /// The store, or the migration failure that stopped it from opening.
    private let store: Result<ModelContainer, any Error>

    init() {
        // StoreSetup copies the store before a migration runs, and mirrors it
        // to iCloud through the CloudKit capability in the entitlements.
        store = Result { try HermeticLaunch.container() }
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
    @Query private var rates: [ExchangeRate]
    @Environment(\.scenePhase) private var scenePhase
    @State private var sync = SyncMonitor()
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var widthClass
    #endif
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    /// A wide screen has room for the charts. A phone does not, so it keeps
    /// the tabs it had. The Mac is always wide.
    private var isWide: Bool {
        #if os(macOS)
        true
        #else
        widthClass == .regular
        #endif
    }

    /// The one place the settings are worked out. Every screen below reads
    /// them from the environment.
    private var settings: AppSettings {
        AppSettings.from(preferences: preferences, rates: rates)
    }

    var body: some View {
        TabView {
            if isWide {
                Tab("Dashboard", systemImage: "square.grid.2x2") {
                    DashboardView()
                }
            }
            Tab("Overview", systemImage: "chart.pie.fill") {
                OverviewView()
            }
            Tab("Budget", systemImage: "target") {
                BudgetsView()
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
        // On an iPad and a Mac this becomes a sidebar; on a phone it stays
        // the tab bar it was.
        .tabViewStyle(.sidebarAdaptable)
        .tint(.appAccent)
        // System follows the device; Light/Dark force a scheme app-wide.
        .preferredColorScheme(appearance.colorScheme)
        .environment(\.settings, settings)
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
