import OsaifuCore
import SwiftData
import SwiftUI
import WidgetKit

/// What the month has spent, read from the same store the app writes, through
/// the App Group. A tap opens the app.
struct SpentThisMonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpentThisMonth", provider: SpentProvider()) { entry in
            SpentWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Spent This Month")
        .description("What this month has spent, and how far through its limit that is.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SpentEntry: TimelineEntry, Sendable {
    let date: Date
    let spent: Money
    /// Nil when the user has set no limit: the widget then shows the spending
    /// on its own, with no bar.
    let progress: BudgetProgress?
}

struct SpentProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpentEntry {
        SpentEntry(date: .now, spent: Money(minorUnits: 0, currencyCode: Currency.defaultCode), progress: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpentEntry) -> Void) {
        Task { @MainActor in completion(SpentEntry.read()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpentEntry>) -> Void) {
        Task { @MainActor in
            // A quarter of an hour is often enough: the app and the intent both
            // ask WidgetKit to reload after a save.
            let next = Date.now.addingTimeInterval(15 * 60)
            completion(Timeline(entries: [SpentEntry.read()], policy: .after(next)))
        }
    }
}

extension SpentEntry {
    /// Reads the store once. On any failure it shows zero rather than nothing,
    /// so the widget never sits blank on the Home Screen.
    @MainActor
    static func read(now: Date = .now) -> SpentEntry {
        guard let container = try? StoreSetup.makeContainer() else {
            return SpentEntry(date: now, spent: Money(minorUnits: 0, currencyCode: Currency.defaultCode), progress: nil)
        }
        let context = ModelContext(container)
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let budgets = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
        let preferences = (try? context.fetch(FetchDescriptor<Preferences>())) ?? []
        let rates = (try? context.fetch(FetchDescriptor<ExchangeRate>())) ?? []

        let home = preferences.max { $0.updatedAt < $1.updatedAt }?.homeCurrencyCode.nilWhenEmpty
            ?? Currency.defaultCode

        let progress = BudgetReader.progress(
            expenses: expenses, budgets: budgets, preferences: preferences,
            rates: rates, homeCurrencyCode: home, month: now
        )

        let spent = progress?.spent ?? ExpenseAnalytics.spend(
            in: expenses, month: now, homeCurrencyCode: home,
            countsForeignSpend: preferences.max { $0.updatedAt < $1.updatedAt }?.countsForeignSpend ?? false,
            rates: [:]
        ).total

        return SpentEntry(date: now, spent: spent, progress: progress)
    }
}

private extension String {
    var nilWhenEmpty: String? { isEmpty ? nil : self }
}

struct SpentWidgetView: View {
    let entry: SpentEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.date, format: .dateTime.month(.wide))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.spent.formatted())
                .font(.title2.bold())
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("spent this month")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let progress = entry.progress {
                ProgressView(value: progress.fraction)
                    .tint(progress.isOver ? .red : .green)
                Text("of \(progress.limit.formatted())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview(as: .systemSmall) {
    SpentThisMonthWidget()
} timeline: {
    SpentEntry(
        date: .now,
        spent: Money(minorUnits: 101_400, currencyCode: "JPY"),
        progress: BudgetProgress(
            baseLimit: Money(minorUnits: 120_000, currencyCode: "JPY"),
            carriedOver: Money.zero("JPY"),
            limit: Money(minorUnits: 120_000, currencyCode: "JPY"),
            spent: Money(minorUnits: 101_400, currencyCode: "JPY"),
            leftOutCount: 0
        )
    )
    SpentEntry(
        date: .now,
        spent: Money(minorUnits: 23_400, currencyCode: "JPY"),
        progress: nil
    )
}
