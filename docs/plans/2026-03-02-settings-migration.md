# Settings Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `UserDefaults`-backed `SettingsManager` with a plain JSON file at `~/.config/doo/settings.json`, and move default data file paths to `~/.local/share/doo/`.

**Architecture:** `SettingsManager` gains a private `SettingsConfig: Codable` struct for JSON encode/decode. `init()` reads from `~/.config/doo/settings.json` (falling back to defaults). Each `didSet` performs an atomic write (encode → tmp file → `FileManager.replaceItemAt`). Tests inject a custom config path via a package-internal `init(configURL:)` to avoid touching `~/.config`.

**Tech Stack:** Swift 6, SwiftUI, XCTest, `Foundation.JSONEncoder/JSONDecoder`, `FileManager.replaceItemAt`

---

### Task 1: Add `SettingsConfig` Codable struct and testable init to `SettingsManager`

**Files:**
- Modify: `Sources/DooKit/Services/SettingsManager.swift`

**Step 1: Write the failing test**

Add a new file `Tests/DooTests/Services/SettingsManagerTests.swift`:

```swift
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
```

**Step 2: Run test to verify it fails**

```bash
swift test --filter DooTests.SettingsManagerTests
```

Expected: compile error — `SettingsManager` has no `init(configURL:)`

**Step 3: Add `SettingsConfig` and `init(configURL:)` to `SettingsManager`**

Replace the entire contents of `Sources/DooKit/Services/SettingsManager.swift`:

```swift
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
public class SettingsManager {
    public static let shared = SettingsManager()

    // MARK: - Codable config

    struct SettingsConfig: Codable {
        var todoFilePath: String
        var doneFilePath: String
        var hotkeyEnabled: Bool
        var launchAtLogin: Bool
    }

    // MARK: - Public properties

    public var todoFilePath: String {
        didSet { saveConfig() }
    }

    public var doneFilePath: String {
        didSet { saveConfig() }
    }

    public var hotkeyEnabled: Bool {
        didSet { saveConfig() }
    }

    public var launchAtLogin: Bool {
        didSet {
            saveConfig()
            updateLaunchAtLogin()
        }
    }

    // MARK: - Private

    private let configURL: URL

    // MARK: - Init

    public convenience init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/doo")
        let url = configDir.appendingPathComponent("settings.json")
        self.init(configURL: url)
    }

    // Package-internal init for testing — accepts any config file URL.
    init(configURL: URL) {
        self.configURL = configURL
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultTodo = "\(home)/.local/share/doo/todo.json"
        let defaultDone = "\(home)/.local/share/doo/done.json"

        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(SettingsConfig.self, from: data) {
            self.todoFilePath = config.todoFilePath
            self.doneFilePath = config.doneFilePath
            self.hotkeyEnabled = config.hotkeyEnabled
            self.launchAtLogin = config.launchAtLogin
        } else {
            self.todoFilePath = defaultTodo
            self.doneFilePath = defaultDone
            self.hotkeyEnabled = true
            self.launchAtLogin = false
        }
    }

    // MARK: - Persistence

    private func saveConfig() {
        let config = SettingsConfig(
            todoFilePath: todoFilePath,
            doneFilePath: doneFilePath,
            hotkeyEnabled: hotkeyEnabled,
            launchAtLogin: launchAtLogin
        )
        do {
            let dir = configURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(config)
            let tmp = dir.appendingPathComponent(".settings.tmp")
            try data.write(to: tmp, options: .atomic)
            _ = try FileManager.default.replaceItemAt(configURL, withItemAt: tmp)
        } catch {
            print("SettingsManager: failed to save config: \(error)")
        }
    }

    // MARK: - Launch at login

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
```

**Step 4: Run test to verify it passes**

```bash
swift test --filter DooTests.SettingsManagerTests
```

Expected: PASS

**Step 5: Commit**

```bash
git add Sources/DooKit/Services/SettingsManager.swift Tests/DooTests/Services/SettingsManagerTests.swift
git commit -m "feat: migrate SettingsManager from UserDefaults to ~/.config/doo/settings.json"
```

---

### Task 2: Add round-trip and corrupt-file tests

**Files:**
- Modify: `Tests/DooTests/Services/SettingsManagerTests.swift`

**Step 1: Add two more test methods**

Append inside the class body (before the closing `}`):

```swift
func testRoundTrip() throws {
    let manager = SettingsManager(configURL: configURL)
    manager.hotkeyEnabled = false
    manager.todoFilePath = tempDir.appendingPathComponent("custom-todo.json").path

    // Re-init from the same file
    let manager2 = SettingsManager(configURL: configURL)
    XCTAssertFalse(manager2.hotkeyEnabled)
    XCTAssertEqual(manager2.todoFilePath, manager.todoFilePath)
}

func testCorruptFileFallsBackToDefaults() throws {
    try "not valid json {{{{".write(to: configURL, atomically: true, encoding: .utf8)
    let manager = SettingsManager(configURL: configURL)
    XCTAssertTrue(manager.hotkeyEnabled)
    XCTAssertTrue(manager.todoFilePath.hasSuffix("/.local/share/doo/todo.json"))
}
```

**Step 2: Run tests**

```bash
swift test --filter DooTests.SettingsManagerTests
```

Expected: all 3 tests PASS

**Step 3: Run full test suite**

```bash
swift test
```

Expected: all 55+ tests PASS (no regressions)

**Step 4: Commit**

```bash
git add Tests/DooTests/Services/SettingsManagerTests.swift
git commit -m "test: add round-trip and corrupt-file tests for SettingsManager"
```

---

### Task 3: Ensure data directories are created on app launch

`DooApp.swift` creates `TaskStore` immediately using the configured paths. If `~/.local/share/doo/` doesn't exist yet, `TaskStore` will fail to write. We ensure the directory exists before handing paths to the store.

**Files:**
- Modify: `Sources/Doo/DooApp.swift`

**Step 1: Update `DooApp.init()` to create the data directory**

Replace the `init()` in `DooApp.swift`:

```swift
init() {
    let s = SettingsManager.shared
    // Ensure the data directory exists before TaskStore opens files
    let todoDir = URL(fileURLWithPath: s.todoFilePath).deletingLastPathComponent()
    let doneDir = URL(fileURLWithPath: s.doneFilePath).deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: todoDir, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: doneDir, withIntermediateDirectories: true)
    _store = State(initialValue: TaskStore(todoPath: s.todoFilePath, donePath: s.doneFilePath))
}
```

**Step 2: Build to confirm no compiler errors**

```bash
swift build
```

Expected: Build complete with no errors.

**Step 3: Commit**

```bash
git add Sources/Doo/DooApp.swift
git commit -m "feat: create ~/.local/share/doo/ on launch if absent"
```

---

### Task 4: Update CLAUDE.md data file defaults

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Update the Data Files table**

In `CLAUDE.md`, find the Data Files table and update the default paths:

| File | Default path | Content |
|------|-------------|---------|
| Todo | `~/.local/share/doo/todo.json` | Active tasks |
| Done | `~/.local/share/doo/done.json` | Completed tasks |
| Settings | `~/.config/doo/settings.json` | App settings |

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with new XDG file paths"
```
