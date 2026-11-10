import OsaifuCore
import SwiftData
import SwiftUI
import WidgetKit

/// What the month has left, on the watch face and in the Smart Stack. It
/// reads the store the watch app writes, through the App Group.
struct LeftThisMonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LeftThisMonth", provider: LeftProvider()) { entry in
            LeftView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Left This Month")
        .description("What the month has left of its limit.")
        .supportedFamilies([.accessoryCorner, .accessoryCircular, .accessoryRectangular])
    }
}

struct LeftEntry: TimelineEntry, Sendable {
    let date: Date
    /// What the month has spent, which is all there is to show with no limit.
    let spent: Money
    /// Nil when the user has set no limit.
    let progress: BudgetProgress?
}

struct LeftProvider: TimelineProvider {
    func placeholder(in context: Context) -> LeftEntry {
        LeftEntry(date: .now, spent: Money.zero(Currency.defaultCode), progress: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LeftEntry) -> Void) {
        Task { @MainActor in completion(LeftEntry.read()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LeftEntry>) -> Void) {
        Task { @MainActor in
            // The watch app asks WidgetKit to reload after a save, so a
            // quarter of an hour covers the rest.
            let next = Date.now.addingTimeInterval(15 * 60)
            completion(Timeline(entries: [LeftEntry.read()], policy: .after(next)))
        }
    }
}

extension LeftEntry {
    /// Reads the store once. On any failure it shows zero rather than
    /// nothing, so the face never carries a blank complication.
    @MainActor
    static func read(now: Date = .now) -> LeftEntry {
        guard let container = try? StoreSetup.makeContainer() else {
            return LeftEntry(date: now, spent: Money.zero(Currency.defaultCode), progress: nil)
        }
        let context = ModelContext(container)
        let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
        let budgets = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
        let preferences = (try? context.fetch(FetchDescriptor<Preferences>())) ?? []
        let rates = (try? context.fetch(FetchDescriptor<ExchangeRate>())) ?? []

        let settings = preferences.max { $0.updatedAt < $1.updatedAt }
        let home = settings.map(\.homeCurrencyCode).flatMap { $0.isEmpty ? nil : $0 }
            ?? Currency.defaultCode

        let progress = BudgetReader.progress(
            expenses: expenses, budgets: budgets, preferences: preferences,
            rates: rates, homeCurrencyCode: home, month: now
        )

        let spent = progress?.spent ?? ExpenseAnalytics.spend(
            in: expenses, month: now, homeCurrencyCode: home,
            countsForeignSpend: settings?.countsForeignSpend ?? false,
            rates: BudgetReader.rateByCurrency(rates, homeCurrencyCode: home)
        ).total

        return LeftEntry(date: now, spent: spent, progress: progress)
    }
}

struct LeftView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LeftEntry

    private var left: Money? { entry.progress?.remaining }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: entry.progress?.fraction ?? 0) {
                Image(systemName: "yensign")
            } currentValueLabel: {
                Text(short(left ?? entry.spent))
                    .minimumScaleFactor(0.5)
            }
            .gaugeStyle(.accessoryCircularCapacity)

        case .accessoryCorner:
            Text(short(left ?? entry.spent))
                .widgetLabel {
                    ProgressView(value: entry.progress?.fraction ?? 0)
                }

        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(left == nil ? "Spent this month" : "Left this month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text((left ?? entry.spent).formatted())
                    .font(.headline)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if let progress = entry.progress {
                    ProgressView(value: progress.fraction)
                        .tint(progress.isOver ? .red : .green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A corner and a circle hold very few characters, so the figure drops
    /// its currency symbol and shortens itself: 21,000 reads as 21K.
    private func short(_ money: Money) -> String {
        money.decimalValue.formatted(
            .number.notation(.compactName).precision(.fractionLength(0))
        )
    }
}
