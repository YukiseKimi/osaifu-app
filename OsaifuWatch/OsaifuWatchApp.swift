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

/// What the watch shows: the pad that takes an expense.
struct WatchRootView: View {
    @Query private var preferences: [Preferences]
    @State private var minorUnits = 0

    /// The newest settings row wins, so the watch and the phone agree.
    private var currencyCode: String {
        let code = preferences.max { $0.updatedAt < $1.updatedAt }?.homeCurrencyCode ?? ""
        return code.isEmpty ? Preferences.legacyCurrencyCode() : code
    }

    var body: some View {
        AmountView(currencyCode: currencyCode, minorUnits: $minorUnits)
            .padding(.horizontal, 4)
    }
}
