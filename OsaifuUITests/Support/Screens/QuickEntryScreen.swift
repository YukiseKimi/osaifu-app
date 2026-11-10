import XCTest

/// The pad: an amount, one of four categories, Save.
@MainActor
struct QuickEntryScreen {
    let journey: JourneyApp
    private let name = "New Expense"

    @discardableResult
    func type(_ digits: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        journey.wait(for: journey.element(A11yIDMirror.QuickEntry.pad), "the pad", on: name, file: file, line: line)
        for digit in digits {
            journey.tap(
                A11yIDMirror.QuickEntry.key(String(digit)),
                "the \(digit) key",
                on: name,
                file: file,
                line: line
            )
        }
        return self
    }

    @discardableResult
    func choose(_ categoryID: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        journey.tap(
            A11yIDMirror.QuickEntry.category(categoryID),
            "the \(categoryID) chip",
            on: name,
            file: file,
            line: line
        )
        return self
    }

    func save(file: StaticString = #filePath, line: UInt = #line) {
        journey.tap(A11yIDMirror.QuickEntry.save, "the Save button", on: name, file: file, line: line)
    }
}
