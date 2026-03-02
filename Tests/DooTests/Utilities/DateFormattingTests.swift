import Foundation
import XCTest
@testable import DooKit

@MainActor
final class DateFormattingTests: XCTestCase {

    func testDateOnlyFormat() {
        let date = dateOnly("2026-03-10")
        let result = DateFormatting.dateOnly(date)
        XCTAssertEqual(result, "2026-03-10")
    }

    func testRelativeReturnsNonEmpty() {
        let date = Date()
        let result = DateFormatting.relative(date)
        XCTAssertFalse(result.isEmpty)
    }

    func testShortDateTimeReturnsNonEmpty() {
        let date = Date()
        let result = DateFormatting.shortDateTime(date)
        XCTAssertFalse(result.isEmpty)
    }

    func testIsOverdueYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(DateFormatting.isOverdue(yesterday))
    }

    func testIsOverdueToday() {
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertFalse(DateFormatting.isOverdue(today))
    }

    func testIsOverdueTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(DateFormatting.isOverdue(tomorrow))
    }
}
