import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class TaskAddTests: XCTestCase {

    private var tempDir: URL!
    private var todoURL: URL!
    private var doneURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooAddTests-\(UUID().uuidString)")
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

    /// Simulates TaskAddCommand logic: parse inline then override with flags.
    private func addTask(
        input: String,
        priority: Int? = nil,
        tags: [String] = [],
        due: String? = nil,
        description: String? = nil,
        status: String? = nil
    ) throws {
        var task = InlineSyntaxParser.parse(input)
        if let p = priority {
            guard (0...2).contains(p) else { throw CLIError.invalidPriority(p) }
            task.priority = p
        }
        if !tags.isEmpty {
            task.tags = Array(Set(task.tags + tags)).sorted()
        }
        if let d = due { task.dueDate = DueDateParser.parse(d) }
        if let desc = description { task.description = desc }
        if let s = status {
            guard let parsed = PipelineStatus.fromShorthand(s) else {
                throw CLIError.invalidStatus(s)
            }
            task.status = parsed
        }
        try makeStore().addTask(task)
    }

    func testAddWithInlineSyntax() throws {
        try addTask(input: "Buy milk !0 #grocery")
        let tasks = makeStore().loadActiveTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].title, "Buy milk")
        XCTAssertEqual(tasks[0].priority, 0)
        XCTAssertEqual(tasks[0].tags, ["grocery"])
    }

    func testAddWithFlagsOnly() throws {
        try addTask(input: "Plain title", priority: 1, tags: ["work"])
        let task = makeStore().loadActiveTasks()[0]
        XCTAssertEqual(task.title, "Plain title")
        XCTAssertEqual(task.priority, 1)
        XCTAssertEqual(task.tags, ["work"])
    }

    func testFlagPriorityOverridesInlinePriority() throws {
        try addTask(input: "Task !2", priority: 0)
        XCTAssertEqual(makeStore().loadActiveTasks()[0].priority, 0)
    }

    func testTagsMergeFromInlineAndFlags() throws {
        try addTask(input: "Task #backend", tags: ["urgent"])
        let tags = makeStore().loadActiveTasks()[0].tags
        XCTAssertTrue(tags.contains("backend"))
        XCTAssertTrue(tags.contains("urgent"))
    }

    func testDuplicateTagsDeduped() throws {
        try addTask(input: "Task #work", tags: ["work"])
        let tags = makeStore().loadActiveTasks()[0].tags
        XCTAssertEqual(tags.filter { $0 == "work" }.count, 1)
    }

    func testAddWithExplicitDueDate() throws {
        try addTask(input: "Task", due: "2026-06-15")
        let task = makeStore().loadActiveTasks()[0]
        XCTAssertNotNil(task.dueDate)
        let components = Calendar.current.dateComponents([.month, .day], from: task.dueDate!)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    func testAddWithDueDateToday() throws {
        try addTask(input: "Task", due: "today")
        let task = makeStore().loadActiveTasks()[0]
        XCTAssertNotNil(task.dueDate)
        XCTAssertEqual(task.dueDate, Calendar.current.startOfDay(for: Date()))
    }

    func testAddWithDueDateTomorrow() throws {
        try addTask(input: "Task", due: "tomorrow")
        let task = makeStore().loadActiveTasks()[0]
        let expected = Calendar.current.date(
            byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())
        )
        XCTAssertEqual(task.dueDate, expected)
    }

    func testFlagDescriptionOverridesInlineDescription() throws {
        try addTask(input: "Task /inline desc", description: "flag desc")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].description, "flag desc")
    }

    func testAddWithInlineDescription() throws {
        try addTask(input: "Task /this is the description")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].description, "this is the description")
    }

    func testDefaultPriorityIsTwo() throws {
        try addTask(input: "Task")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].priority, 2)
    }

    func testInvalidPriorityRejected() throws {
        XCTAssertThrowsError(try addTask(input: "Task", priority: 3)) { error in
            XCTAssertEqual(error as? CLIError, CLIError.invalidPriority(3))
        }
    }

    func testMultipleTasksStoredInOrder() throws {
        try addTask(input: "First")
        try addTask(input: "Second")
        let tasks = makeStore().loadActiveTasks()
        XCTAssertEqual(tasks.count, 2)
        // addTask inserts at index 0, so "Second" is first
        XCTAssertEqual(tasks[0].title, "Second")
        XCTAssertEqual(tasks[1].title, "First")
    }

    func testDefaultStatusIsUntriaged() throws {
        try addTask(input: "Task")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .untriaged)
    }

    func testInlineStatusToken() throws {
        try addTask(input: "Task %backlog")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .backlog)
    }

    func testStatusFlagOverridesInlineStatus() throws {
        try addTask(input: "Task %backlog", status: "inprogress")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .inProgress)
    }

    func testStatusFlagAlone() throws {
        try addTask(input: "Task", status: "inreview")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .inReview)
    }
}
