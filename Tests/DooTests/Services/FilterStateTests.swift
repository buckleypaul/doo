import Foundation
import XCTest
@testable import DooKit

final class FilterStateTests: XCTestCase {

    private var tasks: [DooTask]!

    override func setUp() {
        super.setUp()
        tasks = [
            sampleTask(title: "Buy milk", priority: 3, tags: ["grocery"]),
            sampleTask(title: "Fix login bug", priority: 1, tags: ["backend", "urgent"]),
            sampleTask(title: "Write docs", priority: 2, tags: ["docs"]),
            sampleTask(title: "Deploy app", priority: 4, tags: ["backend"]),
        ]
    }

    func testDefaultFilterReturnsAll() {
        let filter = FilterState()
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result.count, tasks.count)
    }

    func testSearchByTitleCaseInsensitive() {
        let filter = FilterState(searchText: "buy")
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Buy milk")
    }

    func testSearchByTagContent() {
        let filter = FilterState(searchText: "urgent")
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Fix login bug")
    }

    func testFilterByTagSet() {
        let filter = FilterState(selectedTags: ["backend"])
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.tags.contains("backend") })
    }

    func testFilterByPriorityRange() {
        let filter = FilterState(minPriority: 1, maxPriority: 2)
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.priority >= 1 && $0.priority <= 2 })
    }

    func testFilterOverdueOnly() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tasksWithDates = [
            sampleTask(title: "Overdue", dueDate: yesterday),
            sampleTask(title: "Future", dueDate: tomorrow),
            sampleTask(title: "No date"),
        ]
        let filter = FilterState(overdueOnly: true)
        let result = filter.apply(to: tasksWithDates)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Overdue")
    }

    func testSortByPriority() {
        let filter = FilterState(sortOption: .priority)
        let result = filter.apply(to: tasks)
        XCTAssertLessThanOrEqual(result[0].priority, result[1].priority)
        XCTAssertLessThanOrEqual(result[1].priority, result[2].priority)
    }

    func testSortAlphabetical() {
        let filter = FilterState(sortOption: .alphabetical)
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result[0].title, "Buy milk")
        XCTAssertEqual(result[1].title, "Deploy app")
    }

    func testSortDateAddedNewest() {
        let now = Date()
        let older = now.addingTimeInterval(-3600)
        let oldest = now.addingTimeInterval(-7200)
        let tasksWithDates = [
            sampleTask(title: "Oldest", dateAdded: oldest),
            sampleTask(title: "Newest", dateAdded: now),
            sampleTask(title: "Middle", dateAdded: older),
        ]
        let filter = FilterState(sortOption: .dateAddedNewest)
        let result = filter.apply(to: tasksWithDates)
        XCTAssertEqual(result[0].title, "Newest")
        XCTAssertEqual(result[2].title, "Oldest")
    }

    func testSortDueDateSoonest() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let tasksWithDates = [
            sampleTask(title: "No date"),
            sampleTask(title: "Next week", dueDate: nextWeek),
            sampleTask(title: "Tomorrow", dueDate: tomorrow),
        ]
        let filter = FilterState(sortOption: .dueDateSoonest)
        let result = filter.apply(to: tasksWithDates)
        XCTAssertEqual(result[0].title, "Tomorrow")
        XCTAssertEqual(result[1].title, "Next week")
        XCTAssertEqual(result[2].title, "No date")
    }

    func testCombinedSearchAndPriorityFilter() {
        let filter = FilterState(searchText: "bug", minPriority: 1, maxPriority: 2)
        let result = filter.apply(to: tasks)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, "Fix login bug")
    }
}
