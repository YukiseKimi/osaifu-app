import XCTest

/// This Month: the running total, the donut and the per-category rows.
@MainActor
struct OverviewScreen {
    let journey: JourneyApp
    private let name = "This Month"

    func addExpense(file: StaticString = #filePath, line: UInt = #line) {
        journey.tap(A11yIDMirror.Overview.add, "the Add Expense button", on: name, file: file, line: line)
    }

    /// The end state a journey checks: the category's own row, carrying what
    /// that category spent. The amount comes from the data, not from a string
    /// in the test, so a currency the device formats differently still passes.
    func expectCategory(
        _ categoryID: String,
        showing amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = journey.wait(
            for: journey.element(A11yIDMirror.Overview.categoryRow(categoryID)),
            "the \(categoryID) row",
            on: name,
            file: file,
            line: line
        )
        let value = (row.value as? String) ?? ""
        XCTAssertTrue(
            value.contains(amount),
            "\(name): the \(categoryID) row reads \"\(value)\", which does not carry \(amount).",
            file: file,
            line: line
        )
    }
}
