import Foundation
@preconcurrency import XCTest
@testable import DooKit

@MainActor
final class TaskStoreTests: XCTestCase {

    private var tempDir: URL!
    private var store: TaskStore!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        store?.shutdown()
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    private func makeStore() -> TaskStore {
        let todoPath = tempDir.appendingPathComponent("todo.json").path
        let donePath = tempDir.appendingPathComponent("done.json").path
        let s = TaskStore(todoPath: todoPath, donePath: donePath)
        store = s
        return s
    }

    private func readTaskFile(at url: URL) throws -> [DooTask] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TaskFile.self, from: data).tasks
    }

    // MARK: - Tests

    func testInitWithEmptyFilesProducesEmptyArrays() {
        let s = makeStore()
        XCTAssertTrue(s.activeTasks.isEmpty)
        XCTAssertTrue(s.completedTasks.isEmpty)
    }

    func testInitLoadsPreExistingFile() throws {
        let todoURL = tempDir.appendingPathComponent("todo.json")
        let task = sampleTask(title: "Pre-existing")
        try writeTaskFile([task], to: todoURL)

        let s = TaskStore(
            todoPath: todoURL.path,
            donePath: tempDir.appendingPathComponent("done.json").path
        )
        store = s
        XCTAssertEqual(s.activeTasks.count, 1)
        XCTAssertEqual(s.activeTasks[0].title, "Pre-existing")
    }

    func testAddTaskInsertsAtFront() {
        let s = makeStore()
        let task1 = sampleTask(title: "First")
        let task2 = sampleTask(title: "Second")
        s.addTask(task1)
        s.addTask(task2)
        XCTAssertEqual(s.activeTasks[0].title, "Second")
        XCTAssertEqual(s.activeTasks[1].title, "First")
    }

    func testAddTaskPersistsToFile() throws {
        let s = makeStore()
        let task = sampleTask(title: "Persisted")
        s.addTask(task)

        let todoURL = tempDir.appendingPathComponent("todo.json")
        let loaded = try readTaskFile(at: todoURL)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Persisted")
    }

    func testCompleteTaskMovesToCompleted() {
        let s = makeStore()
        let task = sampleTask(title: "To complete")
        s.addTask(task)
        s.completeTask(task)
        XCTAssertTrue(s.activeTasks.isEmpty)
        XCTAssertEqual(s.completedTasks.count, 1)
        XCTAssertEqual(s.completedTasks[0].title, "To complete")
        XCTAssertNotNil(s.completedTasks[0].dateCompleted)
    }

    func testCompleteNonExistentTaskIsNoOp() {
        let s = makeStore()
        let task = sampleTask(title: "Ghost")
        s.completeTask(task)
        XCTAssertTrue(s.activeTasks.isEmpty)
        XCTAssertTrue(s.completedTasks.isEmpty)
    }

    func testUncompleteTaskRestores() {
        let s = makeStore()
        let task = sampleTask(title: "Restore me")
        s.addTask(task)
        s.completeTask(task)
        let completed = s.completedTasks[0]
        s.uncompleteTask(completed)
        XCTAssertEqual(s.activeTasks.count, 1)
        XCTAssertTrue(s.completedTasks.isEmpty)
        XCTAssertNil(s.activeTasks[0].dateCompleted)
    }

    func testUpdateTaskInActiveList() {
        let s = makeStore()
        var task = sampleTask(title: "Original")
        s.addTask(task)
        task.title = "Updated"
        s.updateTask(task)
        XCTAssertEqual(s.activeTasks[0].title, "Updated")
    }

    func testUpdateTaskInCompletedList() {
        let s = makeStore()
        let task = sampleTask(title: "To complete")
        s.addTask(task)
        s.completeTask(task)
        var completed = s.completedTasks[0]
        completed.title = "Updated completed"
        s.updateTask(completed)
        XCTAssertEqual(s.completedTasks[0].title, "Updated completed")
    }

    func testDeleteTaskFromActive() {
        let s = makeStore()
        let task = sampleTask(title: "Delete me")
        s.addTask(task)
        s.deleteTask(task)
        XCTAssertTrue(s.activeTasks.isEmpty)
    }

    func testDeleteTaskFromCompleted() {
        let s = makeStore()
        let task = sampleTask(title: "Complete then delete")
        s.addTask(task)
        s.completeTask(task)
        XCTAssertEqual(s.completedTasks.count, 1)
        let completed = s.completedTasks[0]
        s.deleteTask(completed)
        XCTAssertTrue(s.completedTasks.isEmpty)
    }

    func testUpdateTaskTitle() {
        let s = makeStore()
        s.addTask(sampleTask(title: "Original title"))
        var task = s.activeTasks[0]
        let newTitle = "Updated title from inline edit"
        task.title = newTitle
        s.updateTask(task)
        let reloaded = s.activeTasks.first(where: { $0.id == task.id })
        XCTAssertEqual(reloaded?.title, newTitle)
    }

    func testRemoveTagViaUpdateTask() {
        let s = makeStore()
        var task = sampleTask(tags: ["backend", "frontend"])
        s.addTask(task)
        task.tags.removeAll { $0 == "frontend" }
        s.updateTask(task)
        let stored = s.activeTasks.first { $0.id == task.id }
        XCTAssertEqual(stored?.tags, ["backend"])
    }

    func testRenameTags() {
        let s = makeStore()
        let task1 = sampleTask(tags: ["backend"])
        let task2 = sampleTask(tags: ["backend", "frontend"])
        let task3 = sampleTask(tags: ["frontend"])
        s.addTask(task1)
        s.addTask(task2)
        s.addTask(task3)

        s.renameTags(from: "backend", to: "infrastructure")

        XCTAssertEqual(s.activeTasks[2].tags.sorted(), ["infrastructure"])
        XCTAssertEqual(s.activeTasks[1].tags.sorted(), ["frontend", "infrastructure"])
        XCTAssertEqual(s.activeTasks[0].tags.sorted(), ["frontend"])
    }

    func testMergeTags() {
        let s = makeStore()
        let task1 = sampleTask(tags: ["old"])
        let task2 = sampleTask(tags: ["old", "other"])
        let task3 = sampleTask(tags: ["target"])
        s.addTask(task1)
        s.addTask(task2)
        s.addTask(task3)

        s.mergeTags(source: "old", into: "target")

        XCTAssertEqual(s.activeTasks[2].tags.sorted(), ["target"])
        XCTAssertEqual(s.activeTasks[1].tags.sorted(), ["other", "target"])
        XCTAssertEqual(s.activeTasks[0].tags.sorted(), ["target"])
    }

    func testMergeTagsAvoidsDuplicates() {
        let s = makeStore()
        let task = sampleTask(tags: ["source", "target"])
        s.addTask(task)

        s.mergeTags(source: "source", into: "target")

        XCTAssertEqual(s.activeTasks[0].tags, ["target"])
    }

    func testUpdatePathsReloadsFromNewFiles() throws {
        let s = makeStore()
        s.addTask(sampleTask(title: "Old"))

        let dir2 = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir2) }

        let newTodoURL = dir2.appendingPathComponent("todo.json")
        let newDoneURL = dir2.appendingPathComponent("done.json")
        try writeTaskFile([sampleTask(title: "New")], to: newTodoURL)

        s.updatePaths(todoPath: newTodoURL.path, donePath: newDoneURL.path)
        XCTAssertEqual(s.activeTasks.count, 1)
        XCTAssertEqual(s.activeTasks[0].title, "New")
    }
}
