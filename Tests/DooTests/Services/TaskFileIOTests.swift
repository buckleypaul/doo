import Foundation
import XCTest
@testable import DooCore

final class TaskFileIOTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooTaskFileIOTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadFromMissingFileReturnsEmpty() {
        let url = tempDir.appendingPathComponent("nonexistent.json")
        let tasks = TaskFileIO.loadTasks(from: url)
        XCTAssertTrue(tasks.isEmpty)
    }

    func testSaveAndLoadRoundTrip() throws {
        let url = tempDir.appendingPathComponent("tasks.json")
        let task = DooTask(title: "Round trip", priority: 1, tags: ["test"])
        try TaskFileIO.saveTasks([task], to: url)

        let loaded = TaskFileIO.loadTasks(from: url)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Round trip")
        XCTAssertEqual(loaded[0].priority, 1)
        XCTAssertEqual(loaded[0].tags, ["test"])
    }

    func testSaveCreatesParentDirectories() throws {
        let url = tempDir.appendingPathComponent("nested/dir/tasks.json")
        try TaskFileIO.saveTasks([DooTask(title: "Nested")], to: url)

        let loaded = TaskFileIO.loadTasks(from: url)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Nested")
    }

    func testSaveOverwritesExisting() throws {
        let url = tempDir.appendingPathComponent("tasks.json")
        try TaskFileIO.saveTasks([DooTask(title: "First")], to: url)
        try TaskFileIO.saveTasks([DooTask(title: "Second")], to: url)

        let loaded = TaskFileIO.loadTasks(from: url)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].title, "Second")
    }

    func testLoadCorruptFileReturnsEmpty() throws {
        let url = tempDir.appendingPathComponent("corrupt.json")
        try "not valid json {{".write(to: url, atomically: true, encoding: .utf8)

        let tasks = TaskFileIO.loadTasks(from: url)
        XCTAssertTrue(tasks.isEmpty)
    }
}
