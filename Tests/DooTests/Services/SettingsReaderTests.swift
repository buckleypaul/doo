import Foundation
import XCTest
@testable import DooCore

final class SettingsReaderTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooSettingsReaderTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadMissingFileReturnsDefaults() {
        let url = tempDir.appendingPathComponent("missing.json")
        let config = SettingsReader.load(from: url)
        XCTAssertTrue(config.todoFilePath.hasSuffix("/.local/share/doo/todo.json"))
        XCTAssertTrue(config.doneFilePath.hasSuffix("/.local/share/doo/done.json"))
        XCTAssertTrue(config.hotkeyEnabled)
        XCTAssertFalse(config.launchAtLogin)
        XCTAssertEqual(config.sections.count, 1)
        XCTAssertEqual(config.sections.first?.name, "All Tasks")
    }

    func testLoadValidConfig() throws {
        let url = tempDir.appendingPathComponent("settings.json")
        let config = SettingsConfig(
            todoFilePath: "/custom/todo.json",
            doneFilePath: "/custom/done.json",
            hotkeyEnabled: false,
            launchAtLogin: true
        )
        let data = try JSONEncoder().encode(config)
        try data.write(to: url)

        let loaded = SettingsReader.load(from: url)
        XCTAssertEqual(loaded.todoFilePath, "/custom/todo.json")
        XCTAssertEqual(loaded.doneFilePath, "/custom/done.json")
        XCTAssertFalse(loaded.hotkeyEnabled)
        XCTAssertTrue(loaded.launchAtLogin)
    }

    func testLoadCorruptFileFallsBackToDefaults() throws {
        let url = tempDir.appendingPathComponent("settings.json")
        try "garbage {{".write(to: url, atomically: true, encoding: .utf8)

        let config = SettingsReader.load(from: url)
        XCTAssertTrue(config.hotkeyEnabled)
        XCTAssertTrue(config.todoFilePath.hasSuffix("/.local/share/doo/todo.json"))
    }

    func testLegacyConfigWithoutSectionsMigratesToDefault() throws {
        let url = tempDir.appendingPathComponent("settings.json")
        // Simulate old config with groupByStatus but no sections key
        let json = """
        {
            "todoFilePath": "/custom/todo.json",
            "doneFilePath": "/custom/done.json",
            "hotkeyEnabled": true,
            "launchAtLogin": false,
            "groupByStatus": true
        }
        """
        try json.write(to: url, atomically: true, encoding: .utf8)

        let config = SettingsReader.load(from: url)
        XCTAssertEqual(config.sections.count, 1)
        XCTAssertEqual(config.sections.first?.name, "All Tasks")
        XCTAssertEqual(config.todoFilePath, "/custom/todo.json")
    }

    func testConfigWithMultipleSectionsRoundTrips() throws {
        let url = tempDir.appendingPathComponent("settings.json")
        let sections = [
            TaskSection(name: "Urgent", order: 0, selectedPriorities: Set([0])),
            TaskSection(name: "Backlog", order: 1, selectedStatuses: Set([.backlog])),
        ]
        let config = SettingsConfig(
            todoFilePath: "/tmp/todo.json",
            doneFilePath: "/tmp/done.json",
            sections: sections
        )
        let data = try JSONEncoder().encode(config)
        try data.write(to: url)

        let loaded = SettingsReader.load(from: url)
        XCTAssertEqual(loaded.sections.count, 2)
        XCTAssertEqual(loaded.sections[0].name, "Urgent")
        XCTAssertEqual(loaded.sections[0].selectedPriorities, Set([0]))
        XCTAssertEqual(loaded.sections[1].name, "Backlog")
        XCTAssertEqual(loaded.sections[1].selectedStatuses, Set([.backlog]))
    }
}
