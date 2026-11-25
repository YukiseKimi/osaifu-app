import XCTest

/// The first run: the two questions, and what answering them changes.
final class WelcomeJourney: XCTestCase {

    /// A limit given on the first run reaches the store, and This Month says
    /// what is left of it.
    ///
    /// The sheet writes through `Preferences` and `Budget` and saves, and the
    /// line it feeds is drawn from a separate query. Nothing but a launch
    /// proves that chain: the unit tests either side of it cannot see the
    /// sheet, and the sheet cannot be seen at all unless a journey asks for
    /// it, because every other journey needs it out of the way.
    @MainActor
    func testALimitSetOnTheFirstRunReachesThisMonth() throws {
        continueAfterFailure = false
        let journey = JourneyApp()
        try journey.launch(askingTheFirstRunQuestions: true)

        WelcomeScreen(journey: journey)
            .expectUp()
            .typeLimit("1800")
            .start()

        OverviewScreen(journey: journey).expectBudgetLine(showing: "1,800")

        journey.holdLastScreen()
    }

    /// The questions are asked once. A second launch opens straight on the
    /// month, with the limit the first one set still there.
    @MainActor
    func testTheQuestionsAreNotAskedTwice() throws {
        continueAfterFailure = false
        let journey = JourneyApp()
        try journey.launch(askingTheFirstRunQuestions: true)

        WelcomeScreen(journey: journey).typeLimit("1800").start()
        OverviewScreen(journey: journey).expectBudgetLine(showing: "1,800")

        // Sealed, and without asking for the questions: the way every other
        // journey starts, and the way a second real launch behaves.
        try journey.relaunch()
        OverviewScreen(journey: journey)
            .expectNoWelcome()
            .expectBudgetLine(showing: "1,800")
    }
}
