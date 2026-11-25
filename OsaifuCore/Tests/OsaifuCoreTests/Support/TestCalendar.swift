import Foundation

/// A fixed calendar, so a test gives the same answer in every time zone.
///
/// Eight suites each kept their own copy of this and of `day` below. They
/// were identical, and a change to one of them would have left the other
/// seven saying something else.
let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// A date at midnight UTC, written the way a person says it.
func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    utc.date(from: DateComponents(year: year, month: month, day: day))!
}
