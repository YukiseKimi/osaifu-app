import XCTest

/// This Month: the running total, the donut and the per-category rows.
@MainActor
struct OverviewScreen {
    let journey: JourneyApp
    private let name = "This Month"

    func addExpense(file: StaticString = #filePath, line: UInt = #line) {
        journey.tap(A11yIDMirror.Overview.add, "the Add Expense button", on: name, file: file, line: line)
    }

    /// The line that says what is left of the month. It is drawn only once a
    /// limit is set, so finding it is half of what a journey about the limit
    /// is checking.
    @discardableResult
    func expectBudgetLine(
        showing amount: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let budget = journey.wait(
            for: journey.element(A11yIDMirror.Overview.budgetLine),
            "the budget line",
            on: name,
            file: file,
            line: line
        )
        let text = [budget.label, (budget.value as? String) ?? ""].joined(separator: " ")
        XCTAssertTrue(
            text.contains(amount),
            "\(name): the budget line reads \"\(text)\", which does not carry \(amount).",
            file: file,
            line: line
        )
        return self
    }

    /// The first-run questions are asked once and never again.
    @discardableResult
    func expectNoWelcome(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(
            journey.element(A11yIDMirror.Welcome.limit).waitForExistence(timeout: 2),
            "\(name): the first-run questions came back on a later launch.",
            file: file,
            line: line
        )
        return self
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
