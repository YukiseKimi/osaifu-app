import XCTest

/// The two questions the app asks on a first run: the currency, and what the
/// month may spend.
@MainActor
struct WelcomeScreen {
    let journey: JourneyApp
    private let name = "Welcome"

    /// Waits for the sheet, which is the thing this journey is about.
    @discardableResult
    func expectUp(file: StaticString = #filePath, line: UInt = #line) -> Self {
        journey.wait(
            for: journey.element(A11yIDMirror.Welcome.limit),
            "the monthly limit field",
            on: name,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func typeLimit(_ amount: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let field = journey.wait(
            for: journey.element(A11yIDMirror.Welcome.limit),
            "the monthly limit field",
            on: name,
            file: file,
            line: line
        )
        field.tap()
        field.typeText(amount)
        return self
    }

    func start(file: StaticString = #filePath, line: UInt = #line) {
        journey.tap(A11yIDMirror.Welcome.start, "the Start button", on: name, file: file, line: line)
    }
}
