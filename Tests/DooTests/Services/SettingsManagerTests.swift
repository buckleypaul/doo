import Foundation
@preconcurrency import XCTest
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
        let manager = SettingsManager(configURL: configURL)
        XCTAssertTrue(manager.todoFilePath.hasSuffix("/.local/share/doo/todo.json"))
        XCTAssertTrue(manager.doneFilePath.hasSuffix("/.local/share/doo/done.json"))
        XCTAssertTrue(manager.hotkeyEnabled)
        XCTAssertFalse(manager.launchAtLogin)
    }

    func testRoundTrip() throws {
        let expectedTodoPath = tempDir.appendingPathComponent("custom-todo.json").path
        do {
            let manager = SettingsManager(configURL: configURL)
            manager.hotkeyEnabled = false
            manager.todoFilePath = expectedTodoPath
        }
        let manager2 = SettingsManager(configURL: configURL)
        XCTAssertFalse(manager2.hotkeyEnabled)
        XCTAssertEqual(manager2.todoFilePath, expectedTodoPath)
    }

    func testCorruptFileFallsBackToDefaults() throws {
        try "not valid json {{{{".write(to: configURL, atomically: true, encoding: .utf8)
        let manager = SettingsManager(configURL: configURL)
        XCTAssertTrue(manager.hotkeyEnabled)
        XCTAssertTrue(manager.todoFilePath.hasSuffix("/.local/share/doo/todo.json"))
    }

    // MARK: - Section tests

    func testSectionsDefaultToSingleAllTasks() throws {
        let manager = SettingsManager(configURL: configURL)
        XCTAssertEqual(manager.sections.count, 1)
        XCTAssertEqual(manager.sections.first?.name, "All Tasks")
    }

    func testAddSection() throws {
        let manager = SettingsManager(configURL: configURL)
        manager.addSection(name: "Urgent")
        XCTAssertEqual(manager.sections.count, 2)
        XCTAssertEqual(manager.sections.last?.name, "Urgent")
        XCTAssertEqual(manager.sections.last?.order, 1)
    }

    func testRemoveSection() throws {
        let manager = SettingsManager(configURL: configURL)
        manager.addSection(name: "Urgent")
        XCTAssertEqual(manager.sections.count, 2)

        let urgentID = manager.sections.last!.id
        manager.removeSection(id: urgentID)
        XCTAssertEqual(manager.sections.count, 1)
        XCTAssertEqual(manager.sections.first?.name, "All Tasks")
    }

    func testRemoveLastSectionIsNoOp() throws {
        let manager = SettingsManager(configURL: configURL)
        XCTAssertEqual(manager.sections.count, 1)

        let onlyID = manager.sections.first!.id
        manager.removeSection(id: onlyID)
        XCTAssertEqual(manager.sections.count, 1)
    }

    func testUpdateSection() throws {
        let manager = SettingsManager(configURL: configURL)
        var section = manager.sections.first!
        section.name = "Renamed"
        section.overdueOnly = true
        manager.updateSection(section)

        XCTAssertEqual(manager.sections.first?.name, "Renamed")
        XCTAssertTrue(manager.sections.first?.overdueOnly ?? false)
    }

    func testMoveSections() throws {
        let manager = SettingsManager(configURL: configURL)
        manager.addSection(name: "Second")
        manager.addSection(name: "Third")
        XCTAssertEqual(manager.sections.map(\.name), ["All Tasks", "Second", "Third"])

        // Move "Third" (index 2) to index 0
        manager.moveSections(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(manager.sections.map(\.name), ["Third", "All Tasks", "Second"])
        XCTAssertEqual(manager.sections.map(\.order), [0, 1, 2])
    }

    func testSectionsPersist() throws {
        do {
            let manager = SettingsManager(configURL: configURL)
            manager.addSection(name: "Backlog")
            var section = manager.sections.last!
            section.selectedStatuses = Set([.backlog])
            manager.updateSection(section)
        }
        let manager2 = SettingsManager(configURL: configURL)
        XCTAssertEqual(manager2.sections.count, 2)
        XCTAssertEqual(manager2.sections.last?.name, "Backlog")
        XCTAssertEqual(manager2.sections.last?.selectedStatuses, Set([.backlog]))
    }

    // MARK: - Tag color tests

    func testTagColorsDefaultEmpty() throws {
        let manager = SettingsManager(configURL: configURL)
        XCTAssertTrue(manager.tagColors.isEmpty)
    }

    func testTagColorsPersist() throws {
        do {
            let manager = SettingsManager(configURL: configURL)
            manager.tagColors = ["backend": "#ed8796", "frontend": "#a6da95"]
        }
        let manager2 = SettingsManager(configURL: configURL)
        XCTAssertEqual(manager2.tagColors["backend"], "#ed8796")
        XCTAssertEqual(manager2.tagColors["frontend"], "#a6da95")
    }

    func testAvailableTagColorsDefaultPalette() throws {
        let manager = SettingsManager(configURL: configURL)
        let palette = manager.availableTagColors
        XCTAssertEqual(palette.count, 14)
        XCTAssertEqual(palette.first?.name, "Rosewater")
        XCTAssertEqual(palette.first?.hex, "#f4dbd6")
    }

    func testAvailableTagColorsPersist() throws {
        do {
            let manager = SettingsManager(configURL: configURL)
            let customColors = [
                TagColor(name: "CustomRed", hex: "#ff0000"),
                TagColor(name: "CustomBlue", hex: "#0000ff")
            ]
            manager.availableTagColors = customColors
        }
        let manager2 = SettingsManager(configURL: configURL)
        XCTAssertEqual(manager2.availableTagColors.count, 2)
        XCTAssertEqual(manager2.availableTagColors[0].name, "CustomRed")
        XCTAssertEqual(manager2.availableTagColors[1].hex, "#0000ff")
    }
}
