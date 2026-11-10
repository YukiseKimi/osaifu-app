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
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [Preferences]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var budgets: [Budget]
    @Query private var rates: [ExchangeRate]

    @State private var minorUnits = 0
    @State private var picked: ExpenseCategory?
    @State private var sync = SyncMonitor()

    /// The last amount saved. It drives the haptic and the screen that says
    /// what is left.
    @State private var saved: Money?

    /// The settings, worked out once, by the same rules the phone uses.
    private var settings: AppSettings {
        AppSettings.from(preferences: preferences, rates: rates)
    }

    /// The same four the pad on the phone offers, from the same function.
    private var categories: [ExpenseCategory] {
        ExpenseAnalytics.favouriteCategories(for: expenses)
    }

    /// The first of the four stands until the user picks another.
    private var category: ExpenseCategory? { picked ?? categories.first }

    /// Where the month stands, or nil while the user has set no limit.
    private var progress: BudgetProgress? {
        BudgetReader.progress(expenses: expenses, budgets: budgets, settings: settings)
    }

    /// What the month has spent, for the screen that has no limit to show.
    private var spentThisMonth: Money {
        StoreSnapshot.make(
            expenses: expenses, budgets: budgets, settings: settings
        ).spent
    }

    var body: some View {
        if let saved {
            SavedView(
                money: saved,
                category: category,
                progress: progress,
                spent: spentThisMonth,
                onDone: { self.saved = nil }
            )
            .sensoryFeedback(.success, trigger: saved)
        } else {
            pad
        }
    }

    private var pad: some View {
        VStack(spacing: 5) {
            Spacer(minLength: 0)
            AmountView(currencyCode: settings.homeCurrencyCode, minorUnits: $minorUnits)

            HStack(spacing: 4) {
                // The same three states as the phone: connecting, connected,
                // not connected. It says whether a saved expense is going
                // anywhere, which is what the watch cannot promise.
                SyncBadge(account: sync.account, isConnecting: sync.isConnecting)
                if let category {
                    Text(category.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            CategoryRow(categories: categories, chosen: $picked)

            Button("Save", action: save)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(minorUnits <= 0)
        }
        .padding(.horizontal, 4)
        .task { await sync.refresh(context: modelContext) }
    }

    /// Writes the expense into the store on the watch.
    ///
    /// The write always lands: the store is on this device. CloudKit sends
    /// the row to the phone when the system decides, and the badge above says
    /// whether it can.
    private func save() {
        let money = Money(minorUnits: minorUnits, currencyCode: settings.homeCurrencyCode)
        guard money.minorUnits > 0, let category else { return }
        modelContext.insert(Expense(money: money, category: category))
        try? modelContext.save()
        WidgetRefresh.afterChange()
        saved = money
        minorUnits = 0
    }
}
