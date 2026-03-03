import Foundation
import XCTest
@testable import DooCLILib
@testable import DooCore

final class TaskMoveTests: XCTestCase {

    private var tempDir: URL!
    private var todoURL: URL!
    private var doneURL: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooMoveTests-\(UUID().uuidString)")
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

    /// Simulates TaskMoveCommand logic.
    private func moveTask(id: String, status: String) throws {
        guard let newStatus = PipelineStatus.fromShorthand(status) else {
            throw CLIError.invalidStatus(status)
        }
        let store = makeStore()
        let allTasks = store.loadActiveTasks() + store.loadCompletedTasks()
        var task = try TaskIDResolver.resolve(id, in: allTasks)
        task.status = newStatus
        try store.updateTask(task)
    }

    func testMoveToBacklog() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        try moveTask(id: "1", status: "backlog")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .backlog)
    }

    func testMoveToInProgress() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        try moveTask(id: "1", status: "inprogress")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .inProgress)
    }

    func testMoveToInReview() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        try moveTask(id: "1", status: "in-review")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .inReview)
    }

    func testMoveToTriage() throws {
        let task = DooTask(title: "Task", status: .backlog)
        try makeStore().addTask(task)
        try moveTask(id: "1", status: "triage")
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .triage)
    }

    func testMoveToTriageViaLegacyUntriaged() throws {
        let task = DooTask(title: "Task", status: .backlog)
        try makeStore().addTask(task)
        try moveTask(id: "1", status: "untriaged")   // backward compat
        XCTAssertEqual(makeStore().loadActiveTasks()[0].status, .triage)
    }

    func testInvalidStatusThrows() throws {
        try makeStore().addTask(DooTask(title: "Task"))
        XCTAssertThrowsError(try moveTask(id: "1", status: "invalid")) { error in
            XCTAssertEqual(error as? CLIError, CLIError.invalidStatus("invalid"))
        }
    }
}
