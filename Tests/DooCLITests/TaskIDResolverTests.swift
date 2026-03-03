import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class TaskIDResolverTests: XCTestCase {

    private var tasks: [DooTask]!

    override func setUp() {
        super.setUp()
        tasks = [
            DooTask(id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
                    title: "First"),
            DooTask(id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
                    title: "Second"),
            DooTask(id: UUID(uuidString: "A1B2C3D4-FFFF-0000-1111-222233334444")!,
                    title: "Third"),
        ]
    }

    func testResolveByRowNumber() throws {
        let task = try TaskIDResolver.resolve("1", in: tasks)
        XCTAssertEqual(task.title, "First")

        let task2 = try TaskIDResolver.resolve("2", in: tasks)
        XCTAssertEqual(task2.title, "Second")
    }

    func testResolveRowNumberOutOfRange() {
        XCTAssertThrowsError(try TaskIDResolver.resolve("0", in: tasks)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.taskNotFound("0"))
        }
        XCTAssertThrowsError(try TaskIDResolver.resolve("4", in: tasks)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.taskNotFound("4"))
        }
    }

    func testResolveByUUIDPrefix() throws {
        let task = try TaskIDResolver.resolve("B2C3D4E5", in: tasks)
        XCTAssertEqual(task.title, "Second")
    }

    func testResolveByUUIDPrefixCaseInsensitive() throws {
        let task = try TaskIDResolver.resolve("b2c3d4e5", in: tasks)
        XCTAssertEqual(task.title, "Second")
    }

    func testResolveAmbiguousUUIDPrefix() {
        // Both "First" and "Third" start with "A1B2C3D4"
        XCTAssertThrowsError(try TaskIDResolver.resolve("A1B2C3D4", in: tasks)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.ambiguousTaskID("A1B2C3D4", 2))
        }
    }

    func testResolveNonExistentUUID() {
        XCTAssertThrowsError(try TaskIDResolver.resolve("FFFFFFFF", in: tasks)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.taskNotFound("FFFFFFFF"))
        }
    }

    func testResolveSubtaskByRowNumber() throws {
        let task = DooTask(title: "Parent", subtasks: [
            Subtask(title: "Sub1"),
            Subtask(title: "Sub2"),
        ])
        let sub = try TaskIDResolver.resolveSubtask("2", in: task)
        XCTAssertEqual(sub.title, "Sub2")
    }

    func testResolveSubtaskOutOfRange() {
        let task = DooTask(title: "Parent", subtasks: [Subtask(title: "Sub1")])
        XCTAssertThrowsError(try TaskIDResolver.resolveSubtask("5", in: task)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.subtaskNotFound("5"))
        }
    }
}
