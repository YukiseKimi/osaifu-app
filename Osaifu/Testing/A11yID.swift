/// Every accessibility identifier the app gives a control, in one place.
///
/// A journey never writes a raw string: it asks for one of these, so a
/// renamed control is a compile error in the test rather than a test that
/// quietly stops checking anything. The table in A11yID.md is generated from
/// this file; `script/test.sh ids` fails when the two disagree.
enum A11yID {

    enum Overview {
        /// The list on This Month, which says the screen is up.
        static let list = "overview.list"
        /// The button that opens the pad.
        static let add = "overview.add"
        /// One category's row, carrying what that category spent this month.
        static func categoryRow(_ categoryID: String) -> String { "overview.category.\(categoryID)" }
    }

    enum QuickEntry {
        /// The pad, which says the sheet is up.
        static let pad = "quickEntry.pad"
        /// The amount as the user has typed it so far.
        static let amount = "quickEntry.amount"
        /// One key of the keypad.
        static func key(_ key: String) -> String { "quickEntry.key.\(key)" }
        /// One category chip.
        static func category(_ categoryID: String) -> String { "quickEntry.category.\(categoryID)" }
        static let save = "quickEntry.save"
    }
}
