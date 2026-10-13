import XCTest
@testable import YetAnotherLudditeApp

@MainActor
final class AppModelTests: XCTestCase {
    func testInvalidSaveRetainsStoredRule() {
        let original = Rule(name: "Original", schedule: WeeklySchedule(
            weekdays: [.monday], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 17, minute: 0)
        ), sampleAppIDs: ["demo.app.a"])
        let model = AppModel(repository: FixtureRuleRepository(rules: [original]))
        var draft = original
        draft.name = ""
        draft.schedule.weekdays = []
        draft.sampleAppIDs = []
        XCTAssertFalse(model.save(draft))
        XCTAssertEqual(model.rules, [original])
    }

    func testStorageFailureRetainsStoredRule() {
        let original = Rule(name: "Original", schedule: WeeklySchedule(
            weekdays: [.monday], start: ClockTime(hour: 9, minute: 0), end: ClockTime(hour: 17, minute: 0)
        ), sampleAppIDs: ["demo.app.a"])
        let model = AppModel(repository: FailingRuleRepository(rules: [original]))
        var draft = original
        draft.name = "Updated"
        XCTAssertFalse(model.save(draft))
        XCTAssertEqual(model.rules, [original])
        XCTAssertNotNil(model.errorMessage)
    }

    func testClockRefreshReevaluatesScheduleBoundary() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12, minute: 0))!
        var now = start
        let rule = Rule(name: "Lunch", schedule: WeeklySchedule(weekdays: Set(Weekday.allCases), start: ClockTime(hour: 12, minute: 0), end: ClockTime(hour: 13, minute: 0)), sampleAppIDs: ["demo.app.a"])
        let model = AppModel(repository: FixtureRuleRepository(rules: [rule]), restrictionService: SimulatedRestrictionService(), clock: { now })
        XCTAssertEqual(model.snapshot?.activeRuleIDs, [rule.id])
        now = start.addingTimeInterval(3600)
        model.refreshClock()
        XCTAssertEqual(model.currentDate, now)
        XCTAssertEqual(model.snapshot?.asOf, now)
        XCTAssertEqual(model.snapshot?.activeRuleIDs, [])
    }

    func testPauseUsesActionTimeAndExpiresAtBoundary() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12, minute: 0))!
        var now = start
        let rule = Rule(name: "Lunch", schedule: WeeklySchedule(weekdays: Set(Weekday.allCases), start: ClockTime(hour: 12, minute: 0), end: ClockTime(hour: 13, minute: 0)), sampleAppIDs: ["demo.app.a"])
        let model = AppModel(repository: FixtureRuleRepository(rules: [rule]), restrictionService: SimulatedRestrictionService(), clock: { now })
        now = start.addingTimeInterval(60)
        XCTAssertTrue(model.pause(rule, minutes: 15))
        XCTAssertEqual(model.rules.first?.pauseUntil, now.addingTimeInterval(900))
        XCTAssertEqual(model.snapshot?.activeRuleIDs, [])
        now = now.addingTimeInterval(900)
        model.refreshClock()
        XCTAssertEqual(model.snapshot?.activeRuleIDs, [rule.id])
    }
}

private struct FixtureRuleRepository: RuleRepository {
    var rules: [Rule]
    func load() throws -> [Rule] { rules }
    func save(_ rules: [Rule]) throws {}
    func deleteAll() throws {}
}

private struct FailingRuleRepository: RuleRepository {
    var rules: [Rule]
    func load() throws -> [Rule] { rules }
    func save(_ rules: [Rule]) throws { throw CocoaError(.fileWriteUnknown) }
    func deleteAll() throws {}
}
