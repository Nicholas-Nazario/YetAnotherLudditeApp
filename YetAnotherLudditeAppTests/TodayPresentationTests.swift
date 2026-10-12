import XCTest
@testable import YetAnotherLudditeApp

final class TodayPresentationTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func date(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: hour, minute: minute))!
    }

    private func rules(workPause: Date? = nil) throws -> [Rule] {
        let work = Rule(
            name: "Work Hours",
            schedule: WeeklySchedule(
                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                start: ClockTime(hour: 9, minute: 0),
                end: ClockTime(hour: 17, minute: 0)
            ),
            sampleAppIDs: ["demo.app.a"],
            websites: [try DomainPattern.parse("youtube.com", scope: .includingSubdomains)],
            pauseUntil: workPause
        )
        let lunch = Rule(
            name: "Lunch",
            schedule: WeeklySchedule(
                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                start: ClockTime(hour: 12, minute: 0),
                end: ClockTime(hour: 13, minute: 0)
            ),
            sampleAppIDs: ["demo.app.a"]
        )
        return [work, lunch]
    }

    private func presentation(_ rules: [Rule], at date: Date) -> TodayPresentation {
        let evaluator = RuleEvaluator(calendar: calendar)
        return TodayPresentation(rules: rules, snapshot: evaluator.snapshot(for: rules, at: date), at: date, evaluator: evaluator)
    }

    func testActiveOverlapKeepsEveryReasonAndExplainsNextChange() throws {
        let state = presentation(try rules(), at: date(12, 20))

        XCTAssertEqual(state.tone, .active)
        XCTAssertEqual(state.targets.count, 2)
        XCTAssertEqual(state.targets[0].ruleNames, ["Lunch", "Work Hours"])
        XCTAssertEqual(state.targets[1].typeDescription, "This domain and subdomains")
        XCTAssertTrue(state.nextTitle.contains("Lunch ends"))
        XCTAssertTrue(state.nextDetail.contains("Sample App A would stay restricted by Work Hours"))
    }

    func testPausedRuleShowsRemainingOverlapAndExpectedReturn() throws {
        let state = presentation(try rules(workPause: date(12, 35)), at: date(12, 20))

        XCTAssertEqual(state.tone, .paused)
        XCTAssertEqual(state.targets.map(\.name), ["Sample App A"])
        XCTAssertEqual(state.targets[0].ruleNames, ["Lunch"])
        XCTAssertTrue(state.detail.contains("Work Hours is paused"))
        XCTAssertTrue(state.detail.contains("Sample App A would stay restricted by Lunch"))
        XCTAssertTrue(state.nextTitle.contains("Work Hours resumes"))
        XCTAssertTrue(state.nextDetail.contains("youtube.com and subdomains would become restricted"))
    }

    func testUnrelatedPauseDoesNotRecolorQuietState() throws {
        let state = presentation(try rules(workPause: date(20)), at: date(18, 30))

        XCTAssertEqual(state.tone, .inactive)
        XCTAssertTrue(state.targets.isEmpty)
        XCTAssertEqual(state.title, "Nothing restricted now")
    }

    func testNoRulesHasNoFabricatedChange() {
        let state = presentation([], at: date(12, 20))

        XCTAssertEqual(state.tone, .inactive)
        XCTAssertEqual(state.statusLabel, "No rules")
        XCTAssertEqual(state.nextTitle, "No changes scheduled")
        XCTAssertTrue(state.targets.isEmpty)
    }
}
