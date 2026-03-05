import XCTest
import Foundation

final class NotesURLExtractionTests: XCTestCase {

    private func extractURLs(from notes: String) -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: notes, range: NSRange(notes.startIndex..., in: notes)) ?? []
        return matches.compactMap { $0.url }
    }

    func testExtractURLsFromNotes() {
        let notes = "Check https://github.com/foo/bar and http://example.com for details."
        let urls = extractURLs(from: notes)
        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0].host, "github.com")
        XCTAssertEqual(urls[1].host, "example.com")
    }

    func testEmptyNotesReturnsNoURLs() {
        XCTAssertTrue(extractURLs(from: "").isEmpty)
    }

    func testNotesWithNoURLsReturnsEmpty() {
        let urls = extractURLs(from: "Just some plain text, no links here.")
        XCTAssertTrue(urls.isEmpty)
    }

    func testSingleURL() {
        let urls = extractURLs(from: "See https://apple.com")
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].host, "apple.com")
    }

    func testURLWithPath() {
        let urls = extractURLs(from: "https://github.com/owner/repo/issues/42")
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].host, "github.com")
    }
}
