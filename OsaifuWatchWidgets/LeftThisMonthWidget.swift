import OsaifuModel
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
        LeftEntry(date: .now, spent: StoreSnapshot.empty().spent, progress: nil)
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
    /// The same read the Home Screen widget does.
    @MainActor
    static func read(now: Date = .now) -> LeftEntry {
        let snapshot = StoreSnapshot.read(now: now)
        return LeftEntry(date: now, spent: snapshot.spent, progress: snapshot.progress)
    }
}

struct LeftView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LeftEntry

    private var left: Money? { entry.progress?.remaining }

    /// The figure on the face: what is left, or what the month has spent when
    /// there is no limit to be left of.
    private var figure: Money { left ?? entry.spent }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: entry.progress?.fraction ?? 0) {
                // The sign of the currency the figure is actually in. The
                // number beside it goes without, so the two do not say it
                // twice in a space this small.
                Text(Currency.symbol(forCode: figure.currencyCode))
            } currentValueLabel: {
                Text(short(figure))
                    .minimumScaleFactor(0.5)
            }
            .gaugeStyle(.accessoryCircularCapacity)

        case .accessoryCorner:
            Text(signed(figure))
                .widgetLabel {
                    ProgressView(value: entry.progress?.fraction ?? 0)
                }

        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(left == nil ? "Spent this month" : "Left this month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(figure.formatted())
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

    /// The short figure with its currency's sign, for a corner that has
    /// nowhere else to say which money this is: ¥21K, $240.
    private func signed(_ money: Money) -> String {
        Currency.symbol(forCode: money.currencyCode) + short(money)
    }
}
