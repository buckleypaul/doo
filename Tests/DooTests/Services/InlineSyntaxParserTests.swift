import Foundation
import XCTest
@testable import DooKit

final class InlineSyntaxParserTests: XCTestCase {

    // MARK: - Title extraction

    func testParsesPlainTitle() {
        let task = InlineSyntaxParser.parse("Buy milk")
        XCTAssertEqual(task.title, "Buy milk")
    }

    func testEmptyInputProducesUntitled() {
        let task = InlineSyntaxParser.parse("")
        XCTAssertEqual(task.title, "Untitled")
    }

    func testWhitespaceOnlyProducesUntitled() {
        let task = InlineSyntaxParser.parse("   ")
        XCTAssertEqual(task.title, "Untitled")
    }

    // MARK: - Priority

    func testParsesPriority() {
        let task = InlineSyntaxParser.parse("Fix bug !0")
        XCTAssertEqual(task.priority, 0)
        XCTAssertEqual(task.title, "Fix bug")
    }

    func testDefaultPriorityIsTwo() {
        let task = InlineSyntaxParser.parse("No priority here")
        XCTAssertEqual(task.priority, 2)
    }

    func testPriorityInMiddleOfText() {
        let task = InlineSyntaxParser.parse("Fix !1 the bug")
        XCTAssertEqual(task.priority, 1)
        XCTAssert(task.title.contains("Fix"))
        XCTAssert(task.title.contains("the bug"))
    }

    func testInvalidPriorityIgnored() {
        let task = InlineSyntaxParser.parse("Task !3")
        XCTAssertEqual(task.priority, 2)
        XCTAssert(task.title.contains("!3"))
    }

    // MARK: - Tags

    func testParsesSingleTag() {
        let task = InlineSyntaxParser.parse("Task #backend")
        XCTAssertEqual(task.tags, ["backend"])
        XCTAssertEqual(task.title, "Task")
    }

    func testParsesMultipleTags() {
        let task = InlineSyntaxParser.parse("Task #backend #urgent")
        XCTAssert(task.tags.contains("backend"))
        XCTAssert(task.tags.contains("urgent"))
        XCTAssertEqual(task.tags.count, 2)
    }

    func testTagsAreLowercased() {
        let task = InlineSyntaxParser.parse("Task #Backend #URGENT")
        XCTAssert(task.tags.contains("backend"))
        XCTAssert(task.tags.contains("urgent"))
    }

    // MARK: - Dates

    func testParsesToday() {
        let task = InlineSyntaxParser.parse("Task @today")
        let expected = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(task.dueDate, expected)
    }

    func testParsesTomorrow() {
        let task = InlineSyntaxParser.parse("Task @tomorrow")
        let expected = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
        XCTAssertEqual(task.dueDate, expected)
    }

    func testParsesExplicitDate() {
        let task = InlineSyntaxParser.parse("Task @2026-06-15")
        let expected = dateOnly("2026-06-15")
        XCTAssertEqual(task.dueDate, expected)
    }

    func testInvalidDateIgnored() {
        let task = InlineSyntaxParser.parse("Task @notadate")
        XCTAssertNil(task.dueDate)
    }

    // MARK: - Description

    func testParsesDescription() {
        let task = InlineSyntaxParser.parse("Fix login /check token expiry")
        XCTAssertEqual(task.title, "Fix login")
        XCTAssertEqual(task.description, "check token expiry")
    }

    // MARK: - Status

    func testParsesBacklogStatus() {
        let task = InlineSyntaxParser.parse("Task %backlog")
        XCTAssertEqual(task.status, .backlog)
        XCTAssertEqual(task.title, "Task")
    }

    func testParsesInProgressStatus() {
        let task = InlineSyntaxParser.parse("Task %inprogress")
        XCTAssertEqual(task.status, .inProgress)
    }

    func testParsesInReviewStatus() {
        let task = InlineSyntaxParser.parse("Task %inreview")
        XCTAssertEqual(task.status, .inReview)
    }

    func testNoStatusTokenDefaultsToTriage() {
        let task = InlineSyntaxParser.parse("Task without status")
        XCTAssertEqual(task.status, .triage)
    }

    func testInvalidStatusTokenDefaultsToTriage() {
        let task = InlineSyntaxParser.parse("Task %invalid")
        XCTAssertEqual(task.status, .triage)
        XCTAssertEqual(task.title, "Task")
    }

    func testStatusWithHyphenVariant() {
        let task = InlineSyntaxParser.parse("Task %in-progress")
        XCTAssertEqual(task.status, .inProgress)
    }

    func testStatusWithUnderscoreVariant() {
        let task = InlineSyntaxParser.parse("Task %in_review")
        XCTAssertEqual(task.status, .inReview)
    }

    // MARK: - Combined

    func testParsesAllTokensTogether() {
        let task = InlineSyntaxParser.parse("Fix login bug !0 #backend @tomorrow /check token expiry")
        XCTAssertEqual(task.title, "Fix login bug")
        XCTAssertEqual(task.priority, 0)
        XCTAssertEqual(task.tags, ["backend"])
        XCTAssertNotNil(task.dueDate)
        XCTAssertEqual(task.description, "check token expiry")
    }

    func testParsesAllTokensWithStatus() {
        let task = InlineSyntaxParser.parse("Fix bug !1 %backlog #backend @tomorrow /desc")
        XCTAssertEqual(task.title, "Fix bug")
        XCTAssertEqual(task.priority, 1)
        XCTAssertEqual(task.status, .backlog)
        XCTAssertEqual(task.tags, ["backend"])
        XCTAssertNotNil(task.dueDate)
        XCTAssertEqual(task.description, "desc")
    }
}
