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
}
