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
            notes: "Some notes",
            priority: 1,
            tags: ["work", "urgent"],
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
        )
        let output = TableFormatter.formatTaskDetail(task)

        XCTAssertTrue(output.contains("Title:       Detailed task"))
        XCTAssertTrue(output.contains("Priority:    !1"))
        XCTAssertTrue(output.contains("#work"))
        XCTAssertTrue(output.contains("#urgent"))
        XCTAssertTrue(output.contains("Notes:       Some notes"))
    }

    func testDetailViewOmitsEmptyFields() {
        let task = DooTask(title: "Minimal task")
        let output = TableFormatter.formatTaskDetail(task)

        XCTAssertTrue(output.contains("Title:       Minimal task"))
        XCTAssertFalse(output.contains("Tags:"))
        XCTAssertFalse(output.contains("Due:"))
        XCTAssertFalse(output.contains("Notes:"))
    }

    func testDetailViewShowsStatus() {
        let task = DooTask(title: "Task", status: .inProgress)
        let output = TableFormatter.formatTaskDetail(task)
        XCTAssertTrue(output.contains("Status:      In Progress"))
    }

    func testGroupedListShowsSections() {
        let tasks = [
            DooTask(title: "Triage task", status: .triage),
            DooTask(title: "Backlog task", status: .backlog),
            DooTask(title: "Progress task", status: .inProgress),
        ]
        let output = TableFormatter.formatGroupedTaskList(tasks)
        XCTAssertTrue(output.contains("Triage (1)"))
        XCTAssertTrue(output.contains("Backlog (1)"))
        XCTAssertTrue(output.contains("In Progress (1)"))
        XCTAssertTrue(output.contains("In Review (0)"))
        XCTAssertTrue(output.contains("(none)"))
        XCTAssertTrue(output.contains("3 tasks"))
    }

    func testGroupedListEmptyShowsNoTasks() {
        let output = TableFormatter.formatGroupedTaskList([])
        XCTAssertEqual(output, "No tasks")
    }

    func testGroupedListGlobalRowNumbering() {
        let tasks = [
            DooTask(title: "First", status: .triage),
            DooTask(title: "Second", status: .backlog),
            DooTask(title: "Third", status: .inProgress),
        ]
        let output = TableFormatter.formatGroupedTaskList(tasks)
        // Row numbers should be 1, 2, 3 across groups
        let lines = output.components(separatedBy: "\n")
        let dataLines = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("1") ||
                                        $0.trimmingCharacters(in: .whitespaces).hasPrefix("2") ||
                                        $0.trimmingCharacters(in: .whitespaces).hasPrefix("3") }
        XCTAssertTrue(dataLines.count >= 3)
    }
}
