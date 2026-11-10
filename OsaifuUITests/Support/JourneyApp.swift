import XCTest

/// Launches the app with a store of this run's own, and holds the waits every
/// screen uses. A test never touches XCUIApplication; it goes through this and
/// the screen helpers, so a control that moves is one change here.
@MainActor
struct JourneyApp {
    let app = XCUIApplication()

    /// A way in that the app ships. Osaifu opens on This Month.
    enum Opening {
        case thisMonth

        var page: String {
            switch self {
            case .thisMonth: A11yIDMirror.Overview.list
            }
        }
    }

    /// Starts on an empty store, so a journey never reads what another left.
    func launch(
        _ opening: Opening = .thisMonth,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try start(opening, arguments: ["--sealed", "--reset"], file: file, line: line)
    }

    /// Stops the app and starts it again on the same store, so a journey can
    /// check that what the user saved is still there.
    func relaunch(
        _ opening: Opening = .thisMonth,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        app.terminate()
        try start(opening, arguments: ["--sealed"], file: file, line: line)
    }

    private func start(
        _ opening: Opening,
        arguments: [String],
        file: StaticString,
        line: UInt
    ) throws {
        app.launchArguments = arguments
        app.launch()
        wait(
            for: element(opening.page),
            "the screen the app opens on",
            on: "Launch",
            timeout: 20,
            file: file,
            line: line
        )
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
    }

    /// Waits for what a person would wait to see, never for a fixed time.
    @discardableResult
    func wait(
        for element: XCUIElement,
        _ what: String,
        on screen: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        if !element.waitForExistence(timeout: timeout) {
            XCTFail("\(screen): \(what) never appeared.", file: file, line: line)
        }
        return element
    }

    func tap(
        _ identifier: String,
        _ what: String,
        on screen: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let control = wait(for: element(identifier), what, on: screen, file: file, line: line)
        control.tap()
    }

    /// The one fixed wait there is: it keeps the last screen in a recording.
    func holdLastScreen() {
        Thread.sleep(forTimeInterval: 1)
    }
}
