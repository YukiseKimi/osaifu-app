import OsaifuCore
import SwiftData
import SwiftUI

/// The watch app. It opens the one store that the phone, the widgets and the
/// watch share, so an expense added at the till reaches the phone on its own.
@main
struct OsaifuWatchApp: App {
    /// The store, or the failure that stopped it from opening.
    private let store: Result<ModelContainer, any Error>

    init() {
        store = Result { try StoreSetup.makeContainer() }
    }

    var body: some Scene {
        WindowGroup {
            switch store {
            case .success(let container):
                WatchRootView()
                    .modelContainer(container)
            case .failure:
                // The watch has no room for a long message, and no way to
                // mail a backup. It says what the user can act on.
                ContentUnavailableView(
                    "No data",
                    systemImage: "exclamationmark.icloud",
                    description: Text("Open Osaifu on your iPhone.")
                )
            }
        }
    }
}

/// What the watch shows. The expense pad arrives in the next commit; until
/// then this proves that the watch reads the store the phone writes.
struct WatchRootView: View {
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    var body: some View {
        VStack(spacing: 4) {
            Text("Osaifu")
                .font(.headline)
            Text("\(expenses.count) expenses")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
