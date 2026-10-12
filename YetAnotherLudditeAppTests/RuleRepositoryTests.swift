import XCTest
@testable import YetAnotherLudditeApp

final class RuleRepositoryTests: XCTestCase {
    func testRoundTripAndDelete() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = JSONRuleRepository(fileURL: folder.appendingPathComponent("rules.json"))
        let rule = Rule(
            name: "Work Hours",
            schedule: WeeklySchedule(
                weekdays: [.monday, .tuesday],
                start: ClockTime(hour: 9, minute: 0),
                end: ClockTime(hour: 17, minute: 0)
            ),
            sampleAppIDs: ["demo.app.a"],
            websites: [try DomainPattern.parse("youtube.com", scope: .includingSubdomains)]
        )

        XCTAssertEqual(try repository.load(), [])
        try repository.save([rule])
        XCTAssertEqual(try repository.load(), [rule])
        XCTAssertEqual(try repository.fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        XCTAssertEqual(try folder.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)

        var paused = rule
        paused.pauseUntil = Date(timeIntervalSince1970: 1_800_000_000)
        try repository.save([paused])
        XCTAssertEqual(try repository.load(), [paused])
        XCTAssertEqual(try repository.fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)

        try repository.deleteAll()
        XCTAssertEqual(try repository.load(), [])
    }

    func testUnsupportedFileVersionFailsWithoutOverwriting() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileURL = folder.appendingPathComponent("rules.json")
        let original = Data(#"{"version":99,"rules":[]}"#.utf8)
        try original.write(to: fileURL)

        let repository = JSONRuleRepository(fileURL: fileURL)
        XCTAssertThrowsError(try repository.load())
        XCTAssertEqual(try Data(contentsOf: fileURL), original)
    }
}
