import Foundation
import XCTest
@testable import DooKit

@MainActor
final class SettingsManagerTests: XCTestCase {

    private var tempDir: URL!
    private var configURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DooSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        configURL = tempDir.appendingPathComponent("settings.json")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }

    func testFreshInitUsesDefaults() throws {
        // No file at configURL — should use built-in defaults
        let manager = SettingsManager(configURL: configURL)
        XCTAssertTrue(manager.todoFilePath.hasSuffix("/.local/share/doo/todo.json"))
        XCTAssertTrue(manager.doneFilePath.hasSuffix("/.local/share/doo/done.json"))
        XCTAssertTrue(manager.hotkeyEnabled)
        XCTAssertFalse(manager.launchAtLogin)
    }
}
