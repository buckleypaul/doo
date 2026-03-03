import Foundation
import XCTest
@testable import DooCLILib

final class DueDateParserTests: XCTestCase {

    func testTodayReturnsStartOfToday() {
        let result = DueDateParser.parse("today")
        let expected = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(result, expected)
    }

    func testTodayCaseInsensitive() {
        let result = DueDateParser.parse("TODAY")
        let expected = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(result, expected)
    }

    func testTomorrowReturnsNextDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let expected = Calendar.current.date(byAdding: .day, value: 1, to: today)
        XCTAssertEqual(DueDateParser.parse("tomorrow"), expected)
    }

    func testValidDateStringReturnsParsedDate() {
        let result = DueDateParser.parse("2026-03-15")
        XCTAssertNotNil(result)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 15)
    }

    func testInvalidStringReturnsNil() {
        XCTAssertNil(DueDateParser.parse("not-a-date"))
        XCTAssertNil(DueDateParser.parse(""))
        XCTAssertNil(DueDateParser.parse("13/01/2026"))
    }
}
