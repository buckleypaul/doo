# Doo

macOS 15+ todo app. Swift 6 / SwiftUI. Local JSON storage, no tests.

## Commands

```bash
swift build -c release          # release build → .build/release/Doo
swift run                        # dev run
```

No test suite exists.

## Architecture

```
Doo/
  DooApp.swift          # @main — wires TaskStore → ContentView → AppDelegate
  AppDelegate.swift     # menu bar item, global hotkey (Option+Space)
  Models/
    DooTask.swift       # Codable task struct (custom date coding)
    Subtask.swift
  Services/
    TaskStore.swift     # @Observable — CRUD, atomic file writes, DispatchSource file watching
    SettingsManager.swift  # @Observable — UserDefaults-backed, file paths + hotkey + launch-at-login
    InlineSyntaxParser.swift  # parses "title !N #tag @date /description" → DooTask
  Views/
    MainWindow/         # ContentView (sidebar Todo/Done), TodoListView, DoneListView, TaskRowView, TaskDetailView
    QuickAdd/           # QuickAddPanel (NSPanel), QuickAddView
    Settings/           # SettingsView
  Utilities/
    DateFormatting.swift
```

## Data Files

| File | Default path | Content |
|------|-------------|---------|
| Todo | `~/doo-todo.json` | Active tasks |
| Done | `~/doo-done.json` | Completed tasks |

Both paths are configurable in Settings and stored in UserDefaults.

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
