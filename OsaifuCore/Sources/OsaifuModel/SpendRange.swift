import Foundation

/// The period the dashboard draws: this month, this year, or everything.
///
/// Three words, so the dashboard needs no date pickers.
public enum SpendRange: String, CaseIterable, Identifiable, Sendable {
    case month
    case year
    case all

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .month: "This month"
        case .year: "This year"
        case .all: "All"
        }
    }

    /// The period around `day`, or nil for everything the store holds.
    public func interval(containing day: Date = .now, calendar: Calendar = .current) -> DateInterval? {
        switch self {
        case .month: calendar.dateInterval(of: .month, for: day)
        case .year: calendar.dateInterval(of: .year, for: day)
        case .all: nil
        }
    }
}
