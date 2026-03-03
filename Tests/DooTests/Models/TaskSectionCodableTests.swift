import Foundation
import XCTest
@testable import DooCore

final class TaskSectionCodableTests: XCTestCase {

    func testCodableRoundTrip() throws {
        let section = TaskSection(
            name: "High Priority",
            order: 1,
            isCollapsed: true,
            searchText: "bug",
            selectedTags: Set(["backend", "api"]),
            selectedPriorities: Set([0, 1]),
            selectedStatuses: Set([.inProgress, .inReview]),
            overdueOnly: true,
            sortColumn: "dueDate",
            sortAscending: false
        )

        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(TaskSection.self, from: data)

        XCTAssertEqual(decoded.id, section.id)
        XCTAssertEqual(decoded.name, "High Priority")
        XCTAssertEqual(decoded.order, 1)
        XCTAssertTrue(decoded.isCollapsed)
        XCTAssertEqual(decoded.searchText, "bug")
        XCTAssertEqual(decoded.selectedTags, Set(["backend", "api"]))
        XCTAssertEqual(decoded.selectedPriorities, Set([0, 1]))
        XCTAssertEqual(decoded.selectedStatuses, Set([.inProgress, .inReview]))
        XCTAssertTrue(decoded.overdueOnly)
        XCTAssertEqual(decoded.sortColumn, "dueDate")
        XCTAssertFalse(decoded.sortAscending)
    }

    func testDefaultSection() {
        let section = TaskSection.defaultSection
        XCTAssertEqual(section.name, "All Tasks")
        XCTAssertEqual(section.order, 0)
        XCTAssertFalse(section.isCollapsed)
        XCTAssertTrue(section.searchText.isEmpty)
        XCTAssertTrue(section.selectedTags.isEmpty)
        XCTAssertTrue(section.selectedPriorities.isEmpty)
        XCTAssertTrue(section.selectedStatuses.isEmpty)
        XCTAssertFalse(section.overdueOnly)
        XCTAssertEqual(section.sortColumn, "priority")
        XCTAssertTrue(section.sortAscending)
    }

    func testToFilterStatePriority() {
        let section = TaskSection(sortColumn: "priority", sortAscending: true)
        let filter = section.toFilterState()
        XCTAssertEqual(filter.sortOption, .priority)
    }

    func testToFilterStateTitle() {
        let section = TaskSection(sortColumn: "title", sortAscending: true)
        let filter = section.toFilterState()
        XCTAssertEqual(filter.sortOption, .alphabetical)
    }

    func testToFilterStateDueDate() {
        let section = TaskSection(sortColumn: "dueDate", sortAscending: true)
        let filter = section.toFilterState()
        XCTAssertEqual(filter.sortOption, .dueDateSoonest)
    }

    func testToFilterStateDateAddedNewest() {
        let section = TaskSection(sortColumn: "dateAdded", sortAscending: false)
        let filter = section.toFilterState()
        XCTAssertEqual(filter.sortOption, .dateAddedNewest)
    }

    func testToFilterStateDateAddedOldest() {
        let section = TaskSection(sortColumn: "dateAdded", sortAscending: true)
        let filter = section.toFilterState()
        XCTAssertEqual(filter.sortOption, .dateAddedOldest)
    }

    func testToFilterStateMapsFilterFields() {
        let section = TaskSection(
            searchText: "test",
            selectedTags: Set(["swift"]),
            selectedPriorities: Set([0]),
            selectedStatuses: Set([.backlog]),
            overdueOnly: true
        )
        let filter = section.toFilterState()
        XCTAssertEqual(filter.searchText, "test")
        XCTAssertEqual(filter.selectedTags, Set(["swift"]))
        XCTAssertEqual(filter.selectedPriorities, Set([0]))
        XCTAssertEqual(filter.selectedStatuses, Set([.backlog]))
        XCTAssertTrue(filter.overdueOnly)
    }
}
