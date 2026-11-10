import SwiftUI
import OsaifuCore

extension EnvironmentValues {
    /// The currency that totals and budgets are in, read from the synced
    /// `Preferences` row by `RootView`. An expense keeps the currency it was
    /// entered in, which can differ from this one.
    @Entry var homeCurrencyCode: String = Currency.defaultCode
}
