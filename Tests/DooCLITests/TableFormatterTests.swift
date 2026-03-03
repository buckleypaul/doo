import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class TableFormatterTests: XCTestCase {

    func testEmptyListShowsNoTasks() {
        let output = TableFormatter.formatTaskList([])
        XCTAssertEqual(output, "No tasks")
    }

    func testSingleTaskListFormat() {
        let task = DooTask(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            title: "Buy milk",
            priority: 3,
            tags: ["grocery"],
            dateAdded: Date()
        )
        let output = TableFormatter.formatTaskList([task])

        XCTAssertTrue(output.contains("a1b2c3d4"))
        XCTAssertTrue(output.contains("Buy milk"))
        XCTAssertTrue(output.contains("#grocery"))
        XCTAssertTrue(output.contains("1 task"))
        XCTAssertFalse(output.contains("tasks"))  // singular
    }

    func testMultipleTasksShowsPlural() {
        let tasks = [
            DooTask(title: "Task 1"),
            DooTask(title: "Task 2"),
        ]
        let output = TableFormatter.formatTaskList(tasks)
        XCTAssertTrue(output.contains("2 tasks"))
    }

    func testLongTitleIsTruncated() {
        let task = DooTask(title: "This is a very long task title that exceeds thirty characters")
        let output = TableFormatter.formatTaskList([task])
        XCTAssertTrue(output.contains("This is a very long task ti..."))
    }

    func testDetailViewShowsAllFields() {
        let task = DooTask(
            title: "Detailed task",
            description: "A description",
            notes: "Some notes",
            priority: 1,
            tags: ["work", "urgent"],
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            subtasks: [Subtask(title: "Sub 1"), Subtask(title: "Sub 2", completed: true)]
        )
        let output = TableFormatter.formatTaskDetail(task)

        XCTAssertTrue(output.contains("Title:       Detailed task"))
        XCTAssertTrue(output.contains("Priority:    !1"))
        XCTAssertTrue(output.contains("#work"))
        XCTAssertTrue(output.contains("#urgent"))
        XCTAssertTrue(output.contains("Description: A description"))
        XCTAssertTrue(output.contains("Notes:       Some notes"))
        XCTAssertTrue(output.contains("[ ] Sub 1"))
        XCTAssertTrue(output.contains("[x] Sub 2"))
    }

    func testDetailViewOmitsEmptyFields() {
        let task = DooTask(title: "Minimal task")
        let output = TableFormatter.formatTaskDetail(task)

        XCTAssertTrue(output.contains("Title:       Minimal task"))
        XCTAssertFalse(output.contains("Tags:"))
        XCTAssertFalse(output.contains("Due:"))
        XCTAssertFalse(output.contains("Description:"))
        XCTAssertFalse(output.contains("Notes:"))
        XCTAssertFalse(output.contains("Subtasks:"))
    }
}
