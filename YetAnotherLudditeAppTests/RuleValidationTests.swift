import XCTest
@testable import YetAnotherLudditeApp

final class RuleValidationTests: XCTestCase {
    func testAllInvalidFieldsAreReportedTogetherWithoutChangingEnabled() {
        let rule = Rule(name: "  ", schedule: WeeklySchedule(
            weekdays: [], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 9, minute: 0)
        ))
        XCTAssertEqual(Set(rule.validationErrors.keys), [.name, .days, .times, .targets])
        XCTAssertEqual(rule.validationMessage(), "Give this rule a name.")
        XCTAssertTrue(rule.isEnabled)
    }

    func testMinimumDurationAndOvernightStartDay() {
        var rule = Rule(name: "Night", schedule: WeeklySchedule(
            weekdays: [.monday], start: ClockTime(hour: 23, minute: 50), end: ClockTime(hour: 0, minute: 4)
        ), sampleAppIDs: ["demo.app.a"])
        XCTAssertNotNil(rule.validationErrors[.times])
        rule.schedule.end = ClockTime(hour: 0, minute: 5)
        XCTAssertTrue(rule.validationErrors.isEmpty)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let tuesday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 13, hour: 0, minute: 2))!
        XCTAssertTrue(rule.schedule.contains(tuesday, calendar: calendar))
        XCTAssertEqual(rule.schedule.weekdays, [.monday])
        rule.sampleAppIDs = []
        XCTAssertEqual(Set(rule.validationErrors.keys), [.targets])
    }
}
