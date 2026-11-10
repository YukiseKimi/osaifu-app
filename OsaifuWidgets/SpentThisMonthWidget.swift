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
    /// One shared read, so this widget and the watch complication cannot
    /// disagree about a month.
    @MainActor
    static func read(now: Date = .now) -> SpentEntry {
        let snapshot = StoreSnapshot.read(now: now)
        return SpentEntry(date: now, spent: snapshot.spent, progress: snapshot.progress)
    }
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
