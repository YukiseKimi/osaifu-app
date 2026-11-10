/// Every launch flag the harness may pass.
///
/// `HermeticLaunch` stops on a flag that is not here, so a misspelt flag
/// cannot pass unnoticed and leave a journey testing the live app.
enum LaunchFlag: String, CaseIterable {
    /// Open a store of this run's own, instead of the one the user keeps.
    case sealed = "--sealed"
    /// Empty that store first. Without it a relaunch finds what it left.
    case reset = "--reset"

    static func isKnown(_ argument: String) -> Bool {
        allCases.contains { $0.rawValue == argument }
    }
}
