import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class CLITaskStoreTests: XCTestCase {

    private var tempDir: URL!
    private var todoURL: URL!
    private var doneURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooCLITests-\(UUID().uuidString)")
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

    func testAddAndLoadTask() throws {
        let store = makeStore()
        let task = DooTask(title: "CLI task", priority: 1)
        try store.addTask(task)

        let loaded = store.loadActiveTasks()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "CLI task")
    }

    func testCompleteTask() throws {
        let store = makeStore()
        let task = DooTask(title: "To complete")
        try store.addTask(task)

        let active = store.loadActiveTasks()
        try store.completeTask(active[0])

        XCTAssertTrue(store.loadActiveTasks().isEmpty)
        XCTAssertEqual(store.loadCompletedTasks().count, 1)
        XCTAssertNotNil(store.loadCompletedTasks()[0].dateCompleted)
    }

    func testUncompleteTask() throws {
        let store = makeStore()
        let task = DooTask(title: "To restore")
        try store.addTask(task)

        let active = store.loadActiveTasks()
        try store.completeTask(active[0])

        let done = store.loadCompletedTasks()
        try store.uncompleteTask(done[0])

        XCTAssertEqual(store.loadActiveTasks().count, 1)
        XCTAssertTrue(store.loadCompletedTasks().isEmpty)
        XCTAssertNil(store.loadActiveTasks()[0].dateCompleted)
    }

    func testUpdateTask() throws {
        let store = makeStore()
        let task = DooTask(title: "Original")
        try store.addTask(task)

        var loaded = store.loadActiveTasks()[0]
        loaded.title = "Updated"
        try store.updateTask(loaded)

        XCTAssertEqual(store.loadActiveTasks()[0].title, "Updated")
    }

    func testDeleteTask() throws {
        let store = makeStore()
        try store.addTask(DooTask(title: "Delete me"))

        let task = store.loadActiveTasks()[0]
        try store.deleteTask(task)

        XCTAssertTrue(store.loadActiveTasks().isEmpty)
    }

    func testDeleteNonExistentTaskThrows() {
        let store = makeStore()
        let ghost = DooTask(title: "Ghost")
        XCTAssertThrowsError(try store.deleteTask(ghost))
    }
}
