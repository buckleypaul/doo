# Doo

macOS 15+ todo app. Swift 6 / SwiftUI. Local JSON storage.

## Commands

```bash
swift build -c release          # release build → .build/release/Doo
swift run                        # dev run
swift test                       # run all 59 tests
swift test --filter DooTests.InlineSyntaxParserTests  # single suite
```

If `xcode-select -p` points to Command Line Tools (not Xcode), prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once.

## Testing policy

**All features and bug fixes must include tests.** Add tests to the appropriate file under `Tests/DooTests/`:

- New parsing behaviour → `InlineSyntaxParserTests`
- Model changes or new Codable fields → `DooTaskCodableTests` / `SubtaskCodableTests`
- Filter / sort logic → `FilterStateTests`
- CRUD or persistence → `TaskStoreTests`
- Settings persistence → `SettingsManagerTests`
- Date formatting → `DateFormattingTests`

Run `swift test` and confirm all tests pass before considering any change complete.

## Architecture

```
Sources/
  Doo/                    # Thin executable (2 files)
    DooApp.swift           # @main — wires TaskStore → ContentView → AppDelegate
    AppDelegate.swift      # menu bar item, global hotkey (Option+Space)
  DooKit/                  # Library target (all business logic + views)
    Models/
      DooTask.swift        # Codable task struct (custom date coding)
      Subtask.swift
    Services/
      TaskStore.swift      # @Observable — CRUD, atomic file writes, DispatchSource file watching
      SettingsManager.swift  # @Observable — JSON-backed (~/.config/doo/settings.json), file paths + hotkey + launch-at-login
      InlineSyntaxParser.swift  # parses "title !N #tag @date /description" → DooTask
    Views/
      MainWindow/          # ContentView (sidebar Todo/Done), TodoListView, DoneListView, TaskRowView, TaskDetailView, FilterToolbar
      QuickAdd/            # QuickAddPanel (NSPanel), QuickAddView
      Settings/            # SettingsView
    Utilities/
      DateFormatting.swift
Tests/
  DooTests/                # XCTest target — imports DooKit
    Models/                # DooTaskCodableTests, SubtaskCodableTests
    Services/              # InlineSyntaxParserTests, TaskStoreTests, FilterStateTests, SettingsManagerTests
    Utilities/             # DateFormattingTests
    Helpers/               # TestHelpers (shared factories + utilities)
```

The project uses a library + executable split so tests can `@testable import DooKit`.

## Data Files

| File | Default path | Content |
|------|-------------|---------|
| Todo | `~/.local/share/doo/todo.json` | Active tasks |
| Done | `~/.local/share/doo/done.json` | Completed tasks |
| Settings | `~/.config/doo/settings.json` | App settings |

Both data paths are configurable in Settings. All paths are persisted in `~/.config/doo/settings.json`.

### JSON schema

```json
{
  "tasks": [
    {
      "id": "uuid",
      "title": "Buy milk",
      "priority": 3,
      "tags": ["grocery"],
      "dueDate": "2026-03-10",
      "dateAdded": "2026-03-01T10:00:00Z",
      "dateCompleted": null,
      "description": "optional",
      "notes": "optional freeform",
      "subtasks": []
    }
  ]
}
```

- `dueDate` — date-only string `yyyy-MM-dd` (not ISO 8601)
- `dateAdded` / `dateCompleted` — ISO 8601 with seconds
- `priority` — integer 1 (highest) to 5 (lowest), default 3
- `subtasks` — array of `{id, title, completed}`

The app **live-reloads** within ~100 ms when JSON files change externally. Edit freely.

## Quick-add syntax (InlineSyntaxParser)

```
title text [!1-5] [#tag …] [@today|tomorrow|yyyy-MM-dd] [/description text]
```

Example: `Fix login bug !1 #backend @tomorrow /check token expiry`

## Key patterns

- `TaskStore` uses `isSaving` flag + debounce to avoid echoing its own writes back through the file watcher
- Atomic writes: write to `.filename.tmp` then `FileManager.replaceItemAt`
- `@MainActor` on `TaskStore` and `SettingsManager` — all mutations on main thread
- `AppDelegate` manages the `HotKey` object; re-call `setupHotKey()` after toggling the preference
- `DooApp.onChange(of: settings.*FilePath)` calls `store.updatePaths` to swap file watchers live
- `TaskStore.shutdown()` stops file watchers — call in test tearDown to avoid leaked DispatchSources
