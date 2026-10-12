import XCTest
@testable import YetAnotherLudditeApp

@MainActor
final class AppModelTests: XCTestCase {
    func testResettingPreviewReturnsToLiveDeviceTime() {
        let model = AppModel(repository: EmptyRuleRepository(), restrictionService: SimulatedRestrictionService())
        let chosenTime = Date(timeIntervalSince1970: 1_800_000_000)

        model.previewDate = chosenTime
        XCTAssertEqual(model.currentDate, chosenTime)
        XCTAssertEqual(model.snapshot?.asOf, chosenTime)

        model.previewDate = nil
        XCTAssertLessThan(abs(model.currentDate.timeIntervalSinceNow), 3)
        XCTAssertEqual(model.snapshot?.asOf, model.currentDate)
    }
}

private struct EmptyRuleRepository: RuleRepository {
    func load() throws -> [Rule] { [] }
    func save(_ rules: [Rule]) throws {}
    func deleteAll() throws {}
}
