import XCTest
@testable import YetAnotherLudditeApp

final class DomainPatternTests: XCTestCase {
    func testExactHostDoesNotCoverSiblingSubdomains() throws {
        let exact = try DomainPattern.parse("www.youtube.com", scope: .exactHost)
        XCTAssertTrue(exact.matches(host: "www.youtube.com"))
        XCTAssertFalse(exact.matches(host: "m.youtube.com"))
        XCTAssertTrue(exact.matches(host: "youtube.com"))
        XCTAssertEqual(exact.host, "youtube.com")
    }

    func testAllSubdomainsCoversBaseAndSubdomainsWithHostBoundary() throws {
        let broad = try DomainPattern.parse("YouTube.com", scope: .includingSubdomains)
        XCTAssertEqual(broad.host, "youtube.com")
        XCTAssertEqual(broad.scope, .includingSubdomains)
        XCTAssertTrue(broad.matches(host: "youtube.com"))
        XCTAssertTrue(broad.matches(host: "www.youtube.com"))
        XCTAssertTrue(broad.matches(host: "m.youtube.com"))
        XCTAssertFalse(broad.matches(host: "notyoutube.com"))
        XCTAssertFalse(broad.matches(host: "youtube.com.evil.example"))
    }

    func testPastedURLYieldsHostOnly() throws {
        let pattern = try DomainPattern.parse("https://WWW.YouTube.com/watch?v=abc", scope: .exactHost)
        XCTAssertEqual(pattern.host, "youtube.com")
        XCTAssertEqual(pattern.scope, .exactHost)
    }

    func testBaseHostExactScope() throws {
        let exact = try DomainPattern.parse("YouTube.com", scope: .exactHost)
        XCTAssertTrue(exact.matches(host: "youtube.com"))
        XCTAssertTrue(exact.matches(host: "WWW.YouTube.com."))
        XCTAssertFalse(exact.matches(host: "m.youtube.com"))
        XCTAssertFalse(exact.matches(host: "notyoutube.com"))
        XCTAssertFalse(exact.matches(host: "youtube.com.evil.example"))
    }

    func testNormalizedIdentityRetainsDistinctScopes() throws {
        let exact = try DomainPattern.parse("www.youtube.com", scope: .exactHost)
        XCTAssertEqual(exact, try DomainPattern.parse("youtube.com", scope: .exactHost))
        XCTAssertNotEqual(exact, try DomainPattern.parse("youtube.com", scope: .includingSubdomains))
        let broad = try DomainPattern.parse("www.youtube.com", scope: .includingSubdomains)
        XCTAssertTrue(broad.matches(host: "m.youtube.com"))
        XCTAssertFalse(broad.matches(host: "notyoutube.com"))
    }

    func testInvalidInputIsRejected() {
        XCTAssertThrowsError(try DomainPattern.parse("", scope: .exactHost))
        XCTAssertThrowsError(try DomainPattern.parse("*.com", scope: .exactHost))
        XCTAssertThrowsError(try DomainPattern.parse("*.youtube.com", scope: .exactHost))
        XCTAssertThrowsError(try DomainPattern.parse("hello world.com", scope: .exactHost))
    }
}
