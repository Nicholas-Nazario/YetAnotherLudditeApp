import XCTest
@testable import YetAnotherLudditeApp

final class DomainPatternTests: XCTestCase {
    func testExactHostDoesNotCoverSiblingSubdomains() throws {
        let exact = try DomainPattern.parse("www.youtube.com", scope: .exactHost)
        XCTAssertTrue(exact.matches(host: "www.youtube.com"))
        XCTAssertFalse(exact.matches(host: "m.youtube.com"))
        XCTAssertFalse(exact.matches(host: "youtube.com"))
    }

    func testWildcardInputCoversApexAndSubdomainsWithHostBoundary() throws {
        let wildcard = try DomainPattern.parse("*.YouTube.com", scope: .exactHost)
        XCTAssertEqual(wildcard.host, "youtube.com")
        XCTAssertEqual(wildcard.scope, .includingSubdomains)
        XCTAssertTrue(wildcard.matches(host: "youtube.com"))
        XCTAssertTrue(wildcard.matches(host: "www.youtube.com"))
        XCTAssertTrue(wildcard.matches(host: "m.youtube.com"))
        XCTAssertFalse(wildcard.matches(host: "notyoutube.com"))
        XCTAssertFalse(wildcard.matches(host: "youtube.com.evil.example"))
    }

    func testPastedURLYieldsHostOnly() throws {
        let pattern = try DomainPattern.parse("https://WWW.YouTube.com/watch?v=abc", scope: .exactHost)
        XCTAssertEqual(pattern.host, "www.youtube.com")
        XCTAssertEqual(pattern.scope, .exactHost)
    }

    func testInvalidInputIsRejected() {
        XCTAssertThrowsError(try DomainPattern.parse("", scope: .exactHost))
        XCTAssertThrowsError(try DomainPattern.parse("*.com", scope: .exactHost))
        XCTAssertThrowsError(try DomainPattern.parse("hello world.com", scope: .exactHost))
    }
}
