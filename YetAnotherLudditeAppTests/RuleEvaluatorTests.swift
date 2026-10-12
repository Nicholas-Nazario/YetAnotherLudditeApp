import XCTest
@testable import YetAnotherLudditeApp

final class RuleEvaluatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    private func schedule(
        days: Set<Weekday>,
        start: ClockTime,
        end: ClockTime
    ) -> WeeklySchedule {
        WeeklySchedule(weekdays: days, start: start, end: end)
    }

    func testOvernightScheduleUsesStartDayAndExclusiveEnd() {
        let mondayNight = schedule(
            days: [.monday],
            start: ClockTime(hour: 22, minute: 0),
            end: ClockTime(hour: 7, minute: 0)
        )

        XCTAssertFalse(mondayNight.contains(date(12, 21, 59), calendar: calendar))
        XCTAssertTrue(mondayNight.contains(date(12, 22), calendar: calendar))
        XCTAssertTrue(mondayNight.contains(date(13, 6, 59), calendar: calendar))
        XCTAssertFalse(mondayNight.contains(date(13, 7), calendar: calendar))
        XCTAssertFalse(mondayNight.contains(date(14, 6), calendar: calendar))
    }

    func testOverlapAndPauseLeaveOtherRuleBlocking() {
        let work = Rule(
            name: "Work Hours",
            schedule: schedule(days: [.monday], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 17, minute: 0)),
            sampleAppIDs: ["demo.app.a"],
            pauseUntil: date(12, 12, 45)
        )
        let lunch = Rule(
            name: "Lunch",
            schedule: schedule(days: [.monday], start: ClockTime(hour: 12, minute: 0), end: ClockTime(hour: 13, minute: 0)),
            sampleAppIDs: ["demo.app.a"]
        )
        let evaluator = RuleEvaluator(calendar: calendar)
        let atLunch = date(12, 12, 30)

        var unpausedWork = work
        unpausedWork.pauseUntil = nil
        XCTAssertEqual(
            evaluator.blockingRules(forSampleApp: "demo.app.a", in: [unpausedWork, lunch], at: atLunch).map(\.name),
            ["Lunch", "Work Hours"]
        )

        XCTAssertEqual(evaluator.blockingRules(forSampleApp: "demo.app.a", in: [work, lunch], at: atLunch).map(\.name), ["Lunch"])
        XCTAssertEqual(evaluator.snapshot(for: [work, lunch], at: atLunch).sampleAppReasons["demo.app.a"], [lunch.id])
        XCTAssertEqual(evaluator.snapshot(for: [work, lunch], at: atLunch).nextRuleChange, date(12, 12, 45))
        XCTAssertEqual(evaluator.blockingRules(forSampleApp: "demo.app.a", in: [work, lunch], at: date(12, 12, 45)).map(\.name), ["Lunch", "Work Hours"])
    }

    func testPauseExpiryOutsideScheduleWaitsForNextStart() {
        let rule = Rule(
            name: "Evening",
            schedule: schedule(days: [.monday, .tuesday], start: ClockTime(hour: 20, minute: 0), end: ClockTime(hour: 22, minute: 0)),
            sampleAppIDs: ["demo.app.a"],
            pauseUntil: date(13, 8)
        )
        let evaluator = RuleEvaluator(calendar: calendar)

        XCTAssertEqual(evaluator.snapshot(for: [rule], at: date(12, 21)).nextRuleChange, date(13, 20))
        XCTAssertFalse(rule.isEffective(at: date(13, 8), calendar: calendar))
        XCTAssertTrue(rule.isEffective(at: date(13, 20), calendar: calendar))
    }

    func testMinimumScheduleDurationValidation() {
        let tooShort = Rule(
            name: "Short",
            schedule: schedule(days: [.monday], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 9, minute: 14)),
            sampleAppIDs: ["demo.app.a"]
        )
        let minimum = Rule(
            name: "Enough",
            schedule: schedule(days: [.monday], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 9, minute: 15)),
            sampleAppIDs: ["demo.app.a"]
        )

        XCTAssertNotNil(tooShort.validationMessage())
        XCTAssertNil(minimum.validationMessage())
    }
}
