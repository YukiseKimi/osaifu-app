import XCTest

/// Adding an expense: the flow the whole app exists for.
final class QuickEntryJourney: XCTestCase {

    /// The pad saves an expense, and the expense is still there after the app
    /// has been stopped and started again.
    ///
    /// This is the flow that broke in November 2026: the pad inserted into the
    /// model context and left the write to SwiftData's own schedule, so an
    /// expense added and then killed was gone. Nothing caught it, because
    /// nothing drove the app. This test fails on that code at the relaunch.
    @MainActor
    func testAnExpenseFromThePadSurvivesARelaunch() throws {
        continueAfterFailure = false
        let journey = JourneyApp()
        try journey.launch()

        OverviewScreen(journey: journey).addExpense()
        QuickEntryScreen(journey: journey)
            .type("77")
            .choose("transport")
            .save()

        // It is on the screen that the save worked...
        OverviewScreen(journey: journey).expectCategory("transport", showing: "77")

        // ...and it is still there when the app comes back.
        try journey.relaunch()
        OverviewScreen(journey: journey).expectCategory("transport", showing: "77")

        journey.holdLastScreen()
    }
}
