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
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]

    @State private var minorUnits = 0
    @State private var picked: ExpenseCategory?

    /// The newest settings row wins, so the watch and the phone agree.
    private var currencyCode: String {
        let code = preferences.max { $0.updatedAt < $1.updatedAt }?.homeCurrencyCode ?? ""
        return code.isEmpty ? Preferences.legacyCurrencyCode() : code
    }

    /// The same four the pad on the phone offers, from the same function.
    private var categories: [ExpenseCategory] {
        ExpenseAnalytics.favouriteCategories(for: expenses)
    }

    /// The first of the four stands until the user picks another.
    private var category: ExpenseCategory? { picked ?? categories.first }

    var body: some View {
        VStack(spacing: 6) {
            AmountView(currencyCode: currencyCode, minorUnits: $minorUnits)

            if let category {
                Text(category.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            CategoryRow(categories: categories, chosen: $picked)
        }
        .padding(.horizontal, 4)
    }
}
