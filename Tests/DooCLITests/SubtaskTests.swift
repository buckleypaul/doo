import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class SubtaskTests: XCTestCase {

    private var tempDir: URL!
    private var todoURL: URL!
    private var doneURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooSubtaskTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        todoURL = tempDir.appendingPathComponent("todo.json")
        doneURL = tempDir.appendingPathComponent("done.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeStore() -> CLITaskStore {
        CLITaskStore(todoPath: todoURL.path, donePath: doneURL.path)
    }

    // MARK: - SubtaskAddCommand logic

    func testAddSubtask() throws {
        try makeStore().addTask(DooTask(title: "Parent"))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        task.subtasks.append(Subtask(title: "Child task"))
        try makeStore().updateTask(task)

        let loaded = makeStore().loadActiveTasks()[0]
        XCTAssertEqual(loaded.subtasks.count, 1)
        XCTAssertEqual(loaded.subtasks[0].title, "Child task")
        XCTAssertFalse(loaded.subtasks[0].completed)
    }

    func testAddMultipleSubtasks() throws {
        try makeStore().addTask(DooTask(title: "Parent"))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        task.subtasks.append(Subtask(title: "Sub 1"))
        task.subtasks.append(Subtask(title: "Sub 2"))
        try makeStore().updateTask(task)

        XCTAssertEqual(makeStore().loadActiveTasks()[0].subtasks.count, 2)
    }

    func testAddSubtaskByUUIDPrefix() throws {
        let parent = DooTask(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEFA-234567890123")!,
            title: "Parent"
        )
        try makeStore().addTask(parent)

        var task = try TaskIDResolver.resolve("d4e5f6a7", in: makeStore().loadActiveTasks())
        task.subtasks.append(Subtask(title: "Sub via UUID"))
        try makeStore().updateTask(task)

        XCTAssertEqual(makeStore().loadActiveTasks()[0].subtasks[0].title, "Sub via UUID")
    }

    // MARK: - SubtaskCompleteCommand logic

    func testCompleteSubtaskByRowNumber() throws {
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [
            Subtask(title: "Sub 1"),
            Subtask(title: "Sub 2"),
        ]))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        let subtask = try TaskIDResolver.resolveSubtask("2", in: task)
        guard let index = task.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            XCTFail("Subtask not found"); return
        }
        task.subtasks[index].completed = true
        try makeStore().updateTask(task)

        let loaded = makeStore().loadActiveTasks()[0]
        XCTAssertFalse(loaded.subtasks[0].completed)
        XCTAssertTrue(loaded.subtasks[1].completed)
    }

    func testCompleteSubtaskByUUIDPrefix() throws {
        let sub = Subtask(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            title: "Named sub"
        )
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [sub]))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        let resolved = try TaskIDResolver.resolveSubtask("a1b2c3d4", in: task)
        guard let index = task.subtasks.firstIndex(where: { $0.id == resolved.id }) else {
            XCTFail("Subtask not found"); return
        }
        task.subtasks[index].completed = true
        try makeStore().updateTask(task)

        XCTAssertTrue(makeStore().loadActiveTasks()[0].subtasks[0].completed)
    }

    func testCompleteAlreadyCompletedSubtaskIsIdempotent() throws {
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [
            Subtask(title: "Done", completed: true),
        ]))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        let subtask = try TaskIDResolver.resolveSubtask("1", in: task)
        guard let index = task.subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            XCTFail("Subtask not found"); return
        }
        task.subtasks[index].completed = true
        try makeStore().updateTask(task)

        XCTAssertTrue(makeStore().loadActiveTasks()[0].subtasks[0].completed)
    }

    // MARK: - SubtaskDeleteCommand logic

    func testDeleteSubtaskByRowNumber() throws {
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [
            Subtask(title: "Keep"),
            Subtask(title: "Delete me"),
        ]))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        let subtask = try TaskIDResolver.resolveSubtask("2", in: task)
        task.subtasks.removeAll { $0.id == subtask.id }
        try makeStore().updateTask(task)

        let loaded = makeStore().loadActiveTasks()[0]
        XCTAssertEqual(loaded.subtasks.count, 1)
        XCTAssertEqual(loaded.subtasks[0].title, "Keep")
    }

    func testDeleteSubtaskByUUIDPrefix() throws {
        let sub = Subtask(
            id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
            title: "Named sub"
        )
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [sub, Subtask(title: "Other")]))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        let resolved = try TaskIDResolver.resolveSubtask("b2c3d4e5", in: task)
        task.subtasks.removeAll { $0.id == resolved.id }
        try makeStore().updateTask(task)

        let loaded = makeStore().loadActiveTasks()[0]
        XCTAssertEqual(loaded.subtasks.count, 1)
        XCTAssertEqual(loaded.subtasks[0].title, "Other")
    }

    func testDeleteLastSubtaskLeavesEmptyArray() throws {
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [Subtask(title: "Only")]))

        var task = try TaskIDResolver.resolve("1", in: makeStore().loadActiveTasks())
        let subtask = try TaskIDResolver.resolveSubtask("1", in: task)
        task.subtasks.removeAll { $0.id == subtask.id }
        try makeStore().updateTask(task)

        XCTAssertTrue(makeStore().loadActiveTasks()[0].subtasks.isEmpty)
    }

    func testDeleteSubtaskOutOfRangeThrows() throws {
        try makeStore().addTask(DooTask(title: "Parent", subtasks: [Subtask(title: "Only")]))
        let task = makeStore().loadActiveTasks()[0]
        XCTAssertThrowsError(try TaskIDResolver.resolveSubtask("5", in: task)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.subtaskNotFound("5"))
        }
    }
}
