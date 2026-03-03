import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class TaskEditTests: XCTestCase {

    private var tempDir: URL!
    private var todoURL: URL!
    private var doneURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooEditTests-\(UUID().uuidString)")
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

    /// Simulates TaskEditCommand logic: resolve by ID, apply edits, save.
    private func editTask(
        id: String,
        title: String? = nil,
        priority: Int? = nil,
        addTags: [String] = [],
        removeTags: [String] = [],
        due: String? = nil,
        description: String? = nil,
        notes: String? = nil
    ) throws {
        let store = makeStore()
        let allTasks = store.loadActiveTasks() + store.loadCompletedTasks()
        var task = try TaskIDResolver.resolve(id, in: allTasks)
        if let t = title { task.title = t }
        if let p = priority {
            guard (0...2).contains(p) else { throw CLIError.invalidPriority(p) }
            task.priority = p
        }
        if !addTags.isEmpty {
            task.tags = Array(Set(task.tags + addTags)).sorted()
        }
        if !removeTags.isEmpty {
            task.tags = task.tags.filter { !removeTags.contains($0) }
        }
        if let d = due {
            task.dueDate = d.lowercased() == "none" ? nil : DueDateParser.parse(d)
        }
        if let desc = description {
            task.description = desc.lowercased() == "none" ? nil : desc
        }
        if let n = notes {
            task.notes = n.lowercased() == "none" ? nil : n
        }
        try store.updateTask(task)
    }

    func testEditTitle() throws {
        try makeStore().addTask(DooTask(title: "Original"))
        try editTask(id: "1", title: "Updated")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].title, "Updated")
    }

    func testEditPriority() throws {
        try makeStore().addTask(DooTask(title: "Task", priority: 2))
        try editTask(id: "1", priority: 0)
        XCTAssertEqual(makeStore().loadActiveTasks()[0].priority, 0)
    }

    func testAddTag() throws {
        try makeStore().addTask(DooTask(title: "Task", tags: ["existing"]))
        try editTask(id: "1", addTags: ["newtag"])
        let tags = makeStore().loadActiveTasks()[0].tags
        XCTAssertTrue(tags.contains("existing"))
        XCTAssertTrue(tags.contains("newtag"))
    }

    func testAddTagDeduplicates() throws {
        try makeStore().addTask(DooTask(title: "Task", tags: ["work"]))
        try editTask(id: "1", addTags: ["work"])
        XCTAssertEqual(makeStore().loadActiveTasks()[0].tags.filter { $0 == "work" }.count, 1)
    }

    func testRemoveTag() throws {
        try makeStore().addTask(DooTask(title: "Task", tags: ["keep", "remove"]))
        try editTask(id: "1", removeTags: ["remove"])
        let tags = makeStore().loadActiveTasks()[0].tags
        XCTAssertTrue(tags.contains("keep"))
        XCTAssertFalse(tags.contains("remove"))
    }

    func testRemoveNonExistentTagIsNoOp() throws {
        try makeStore().addTask(DooTask(title: "Task", tags: ["work"]))
        try editTask(id: "1", removeTags: ["nonexistent"])
        XCTAssertEqual(makeStore().loadActiveTasks()[0].tags, ["work"])
    }

    func testSetDueDate() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        try editTask(id: "1", due: "2026-06-15")
        let task = makeStore().loadActiveTasks()[0]
        XCTAssertNotNil(task.dueDate)
        let components = Calendar.current.dateComponents([.month, .day], from: task.dueDate!)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    func testClearDueDateWithNone() throws {
        var task = DooTask(title: "Task")
        task.dueDate = Date()
        try makeStore().addTask(task)
        try editTask(id: "1", due: "none")
        XCTAssertNil(makeStore().loadActiveTasks()[0].dueDate)
    }

    func testClearDueDateNoneCaseInsensitive() throws {
        var task = DooTask(title: "Task")
        task.dueDate = Date()
        try makeStore().addTask(task)
        try editTask(id: "1", due: "NONE")
        XCTAssertNil(makeStore().loadActiveTasks()[0].dueDate)
    }

    func testSetDescription() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        try editTask(id: "1", description: "New description")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].description, "New description")
    }

    func testClearDescriptionWithNone() throws {
        var task = DooTask(title: "Task")
        task.description = "Old description"
        try makeStore().addTask(task)
        try editTask(id: "1", description: "none")
        XCTAssertNil(makeStore().loadActiveTasks()[0].description)
    }

    func testSetNotes() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        try editTask(id: "1", notes: "Some notes")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].notes, "Some notes")
    }

    func testClearNotesWithNone() throws {
        var task = DooTask(title: "Task")
        task.notes = "Old notes"
        try makeStore().addTask(task)
        try editTask(id: "1", notes: "none")
        XCTAssertNil(makeStore().loadActiveTasks()[0].notes)
    }

    func testInvalidPriorityRejectedOnEdit() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        XCTAssertThrowsError(try editTask(id: "1", priority: 5)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.invalidPriority(5))
        }
    }

    func testEditByUUIDPrefix() throws {
        let task = DooTask(
            id: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            title: "Original"
        )
        try makeStore().addTask(task)
        try editTask(id: "c3d4e5f6", title: "Updated")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].title, "Updated")
    }

    func testEditCompletedTask() throws {
        let store = makeStore()
        try store.addTask(DooTask(title: "Task"))
        try store.completeTask(store.loadActiveTasks()[0])
        try editTask(id: "1", title: "Edited Done")
        XCTAssertEqual(makeStore().loadCompletedTasks()[0].title, "Edited Done")
    }
}
