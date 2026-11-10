/// The identifiers, as the test target sees them.
///
/// A UI test bundle cannot import the app, so the registry cannot be shared
/// as code. `script/test.sh ids` compares this with the app's A11yID.swift
/// and fails the run when they differ, which is what keeps them one list.
enum A11yIDMirror {

    enum Overview {
        static let list = "overview.list"
        static let add = "overview.add"
        static func categoryRow(_ categoryID: String) -> String { "overview.category.\(categoryID)" }
    }

    enum QuickEntry {
        static let pad = "quickEntry.pad"
        static let amount = "quickEntry.amount"
        static func key(_ key: String) -> String { "quickEntry.key.\(key)" }
        static func category(_ categoryID: String) -> String { "quickEntry.category.\(categoryID)" }
        static let save = "quickEntry.save"
    }
}
