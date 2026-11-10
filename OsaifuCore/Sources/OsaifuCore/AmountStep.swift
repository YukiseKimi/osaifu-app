import Foundation

/// How much one turn of the Digital Crown, or one press of a button, changes
/// an amount on the watch.
///
/// A fixed step is wrong at one end or the other: a step of 10 is slow for a
/// large amount, and a step of 100 is clumsy for a small one. The step
/// follows the amount instead. Every amount here is in whole minor units, so
/// 1,280 is ¥1,280 and also $12.80.
public enum AmountStep {

    /// The largest amount the watch accepts.
    public static let maximum = 9_999_999

    /// The step for one amount.
    public static func of(_ minorUnits: Int) -> Int {
        switch abs(minorUnits) {
        case ..<1_000: 10
        case ..<10_000: 100
        default: 1_000
        }
    }

    /// The next amount up. It stops at `maximum`.
    ///
    /// The result is a multiple of the step, so an amount that a tier boundary
    /// left untidy becomes tidy on the first press.
    public static func up(from minorUnits: Int) -> Int {
        let start = max(0, minorUnits)
        let step = of(start)
        return min(maximum, (start / step + 1) * step)
    }

    /// The next amount down. It stops at zero.
    ///
    /// It takes the step of the amount below this one, so a step up and a step
    /// down across a tier boundary give back the amount they started from.
    public static func down(from minorUnits: Int) -> Int {
        guard minorUnits > 0 else { return 0 }
        let step = of(minorUnits - 1)
        return max(0, ((minorUnits - 1) / step) * step)
    }
}
