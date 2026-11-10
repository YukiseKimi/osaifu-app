import Testing
import Foundation
@testable import OsaifuCore

private let now = Date(timeIntervalSince1970: 1_800_000_000)

private func expense(_ category: ExpenseCategory, daysAgo: Int) -> Expense {
    Expense(
        money: Money(minorUnits: 100, currencyCode: "JPY"),
        category: category,
        date: now.addingTimeInterval(-Double(daysAgo) * 86_400)
    )
}

@Suite("The categories the pad offers")
struct FavouriteCategoriesTests {

    private func favourites(_ expenses: [Expense], within days: Int = 30) -> [ExpenseCategory] {
        ExpenseAnalytics.favouriteCategories(for: expenses, within: days, now: now)
    }

    @Test("A first launch still offers four")
    func firstLaunchHasFour() {
        let offered = favourites([])
        #expect(offered.count == 4)
        #expect(offered == Array(ExpenseCategory.allCases.prefix(4)))
    }

    @Test("The most used comes first")
    func mostUsedFirst() {
        let offered = favourites([
            expense(.transport, daysAgo: 1),
            expense(.food, daysAgo: 2),
            expense(.food, daysAgo: 3),
            expense(.food, daysAgo: 4),
            expense(.transport, daysAgo: 5),
            expense(.travel, daysAgo: 6)
        ])
        #expect(offered.prefix(3) == [.food, .transport, .travel])
    }

    @Test("An old habit drops out of the window")
    func oldHabitDropsOut() {
        let offered = favourites([
            expense(.travel, daysAgo: 60),
            expense(.travel, daysAgo: 61),
            expense(.groceries, daysAgo: 2)
        ])
        #expect(offered.first == .groceries)
    }

    @Test("A tie keeps one order")
    func tiesKeepOneOrder() {
        let twice = favourites([
            expense(.health, daysAgo: 1),
            expense(.education, daysAgo: 2)
        ])
        #expect(twice.prefix(2) == [.education, .health])
    }

    @Test("An expense dated in the future does not count")
    func futureDoesNotCount() {
        let offered = favourites([
            expense(.travel, daysAgo: -5),
            expense(.groceries, daysAgo: 1)
        ])
        #expect(offered.first == .groceries)
    }
}
