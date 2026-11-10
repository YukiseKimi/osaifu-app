import SwiftUI
import OsaifuCore

extension EnvironmentValues {
    /// The settings, read once from the synced rows by the root view and
    /// handed down. A screen that needs the home currency, the rollover
    /// switch or a rate asks for this, rather than query the rows and work
    /// the answer out again.
    @Entry var settings: AppSettings = AppSettings(homeCurrencyCode: Currency.defaultCode)
}
