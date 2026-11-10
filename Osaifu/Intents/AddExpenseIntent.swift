import AppIntents
import Foundation
import SwiftData
import OsaifuCore

/// Lets Siri, the Shortcuts app, the Action button and the Control Center add
/// an expense without opening Osaifu.
///
/// It asks for an amount and a category: the shortest sentence that still
/// files the expense where it belongs.
struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add an Expense"
    static let description = IntentDescription("Adds an expense to Osaifu, in your home currency.")
    static let openAppWhenRun = false

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category")
    var category: CategoryChoice

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) for \(\.$category)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            throw $amount.needsValueError("How much was it?")
        }

        // The same store the app and the widget read, opened the same way.
        let context = ModelContext(try StoreSetup.makeContainer())
        let home = (try? Preferences.current(
            in: context,
            fallbackCurrencyCode: Preferences.legacyCurrencyCode()
        ).homeCurrencyCode) ?? Currency.defaultCode

        let money = Money(decimal: Decimal(amount), currencyCode: home)
        context.insert(Expense(money: money, category: category.category))
        try context.save()
        WidgetRefresh.afterChange()

        return .result(dialog: "Added \(money.formatted()) for \(category.category.title).")
    }
}

/// "Add an expense to Osaifu", with no setting up by the user.
struct OsaifuShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense to \(.applicationName)",
                "Log a spend in \(.applicationName)"
            ],
            shortTitle: "Add an Expense",
            systemImageName: "plus.circle.fill"
        )
    }
}
