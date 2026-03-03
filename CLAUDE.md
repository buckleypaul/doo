# Doo

macOS 15+ todo app. Swift 6 / SwiftUI. Local JSON storage. Includes a CLI (`doo task ...`).

## Commands

```bash
swift build -c release          # release build → .build/release/Doo + .build/release/DooCLI
swift run Doo                    # dev run (GUI)
swift run DooCLI                 # dev run (CLI)
swift test                       # run all tests
swift test --filter DooTests.InlineSyntaxParserTests  # single suite
swift test --filter DooCLITests                        # CLI tests only
```

If `xcode-select -p` points to Command Line Tools (not Xcode), prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` or run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once.

## Testing policy

**All features and bug fixes must include tests.** Add tests to the appropriate file:

Under `Tests/DooTests/`:
- New parsing behaviour → `InlineSyntaxParserTests`
- Model changes or new Codable fields → `DooTaskCodableTests` / `SubtaskCodableTests`
- Filter / sort logic → `FilterStateTests`
- CRUD or persistence → `TaskStoreTests`
- Settings persistence → `SettingsManagerTests`
- Date formatting → `DateFormattingTests`
- File I/O → `TaskFileIOTests`
- Settings reader → `SettingsReaderTests`

Under `Tests/DooCLITests/`:
- CLI task store → `CLITaskStoreTests`
- Task ID resolution → `TaskIDResolverTests`
- Table formatting → `TableFormatterTests`
- Due date parsing → `DueDateParserTests`
- CLI task add command → `TaskAddTests`
- CLI task edit command → `TaskEditTests`
- CLI list filtering/priority ranges → `TaskListFilterTests`
- CLI task move command → `TaskMoveTests`
- CLI subtask commands → no test file yet (create `SubtaskTests.swift` when adding)

Run `swift test` and confirm all tests pass before considering any change complete.

## Architecture

```
Sources/
  DooCore/                 # Pure Foundation library (shared between GUI + CLI)
    Models/
      DooTask.swift         # Codable task struct (custom date coding)
      PipelineStatus.swift  # PipelineStatus enum: untriaged, backlog, inProgress, inReview
      Subtask.swift
    Services/
      InlineSyntaxParser.swift  # parses "title !N #tag @date %status /description" → DooTask
      FilterState.swift     # SortOption + FilterState (filter/sort logic)
      TaskFileIO.swift      # load/save tasks to JSON (atomic writes)
      SettingsReader.swift  # Read-only settings config + SettingsConfig struct
    Utilities/
      DateFormatting.swift
  DooKit/                  # GUI library target (SwiftUI views + @Observable services)
    DooStyle.swift           # Shared design constants (priorityColor, Spacing, Radius, Size)
    DooKitExports.swift     # @_exported import DooCore
    Services/
      TaskStore.swift       # @Observable — CRUD, file watching, delegates I/O to TaskFileIO
      SettingsManager.swift # @Observable — JSON-backed settings, uses SettingsConfig
    Views/
      MainWindow/           # ContentView, TodoListView, DoneListView, TaskDetailView, FilterToolbar, DeleteButtonCell, CompleteButtonCell
      QuickAdd/             # QuickAddPanel (NSPanel), QuickAddView
      Settings/             # SettingsView
  Doo/                     # GUI executable (2 files)
    DooApp.swift            # @main — wires TaskStore → ContentView → AppDelegate
    AppDelegate.swift       # menu bar item, global hotkey (Option+Space)
  DooCLILib/               # CLI library target (testable)
    Commands/               # ArgumentParser commands (task add/list/show/complete/uncomplete/edit/delete/move, subtask add/complete/delete)
    Services/
      CLITaskStore.swift    # Lightweight file I/O (no watchers/Observable)
      TaskIDResolver.swift  # Row number + UUID prefix resolution
      CLIError.swift        # LocalizedError cases
    Formatting/
      TableFormatter.swift  # Compact table + detail view
      JSONOutput.swift      # --json helpers
    Utilities/
      DueDateParser.swift   # Parses "today" / "tomorrow" / "yyyy-MM-dd" → Date
  DooCLI/                  # CLI executable
    DooCommand.swift        # @main entry point
Tests/
  DooTests/                # XCTest target — imports DooKit + DooCore
    Models/                 # DooTaskCodableTests, SubtaskCodableTests
    Services/               # InlineSyntaxParserTests, TaskStoreTests, FilterStateTests, SettingsManagerTests, TaskFileIOTests, SettingsReaderTests
    Utilities/              # DateFormattingTests
    Helpers/                # TestHelpers (shared factories + utilities)
  DooCLITests/             # XCTest target — imports DooCLILib + DooCore
                            # CLITaskStoreTests, TaskIDResolverTests, TableFormatterTests,
                            # DueDateParserTests, TaskAddTests, TaskEditTests, TaskListFilterTests,
                            # TaskMoveTests
```

The project uses library + executable splits so tests can `@testable import DooKit` / `@testable import DooCLILib`.

## CLI Usage

```bash
doo task add "Fix bug !1 #backend @tomorrow %backlog /check tokens"  # inline syntax
doo task add "Fix bug" --priority 1 --tag backend --due tomorrow --status backlog  # flags
doo task add "Fix bug !1" --tag extra                         # both merge

doo task list                              # active tasks, grouped by status
doo task list --done                       # completed tasks (flat)
doo task list --json                       # JSON output
doo task list --tag backend --overdue --sort priority
doo task list --search "bug" --min-priority 1 --max-priority 2
doo task list --status backlog             # filter by pipeline status
doo task list --status backlog --status inprogress  # multiple statuses

doo task show <ID>                         # detailed view (includes status)
doo task show <ID> --json                  # JSON output

doo task complete <ID>                     # mark complete
doo task uncomplete <ID>                   # restore to active

doo task move <ID> backlog                 # move to pipeline status
doo task move <ID> inprogress              # accepts: untriaged, backlog, inprogress, inreview

doo task edit <ID> --priority 2 --tag new --remove-tag old --due none
doo task edit <ID> --status inreview       # change status via edit
doo task delete <ID>

doo task subtask add <taskID> "subtask title"
doo task subtask complete <taskID> <subtaskID>
doo task subtask delete <taskID> <subtaskID>
```

Task IDs: row numbers (1, 2, 3...) or short UUID prefixes (first 8 chars) shown in list output.

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
      "priority": 2,
      "tags": ["grocery"],
      "dueDate": "2026-03-10",
      "dateAdded": "2026-03-01T10:00:00Z",
      "dateCompleted": null,
      "status": "untriaged",
      "description": "optional",
      "notes": "optional freeform",
      "subtasks": []
    }
  ]
}
```

- `dueDate` — date-only string `yyyy-MM-dd` (not ISO 8601)
- `dateAdded` / `dateCompleted` — ISO 8601 with seconds
- `priority` — integer 0 (highest) to 2 (lowest), default 2
- `status` — pipeline status string: `"untriaged"`, `"backlog"`, `"in_progress"`, `"in_review"` (default `"untriaged"`, missing field decodes as untriaged)
- `subtasks` — array of `{id, title, completed}`

The GUI **live-reloads** within ~100 ms when JSON files change externally (including CLI edits).

## Quick-add syntax (InlineSyntaxParser)

```
title text [!0-2] [#tag …] [@today|tomorrow|yyyy-MM-dd] [%status] [/description text]
```

Example: `Fix login bug !1 #backend @tomorrow %backlog /check token expiry`

Status shortcuts: `%untriaged`, `%backlog`, `%inprogress` (or `%in-progress`, `%in_progress`), `%inreview` (or `%in-review`, `%in_review`)

## Key patterns

- `TaskStore` uses `isSaving` flag + debounce to avoid echoing its own writes back through the file watcher
- Atomic writes: write to `.filename.tmp` then `FileManager.replaceItemAt` (in `TaskFileIO`)
- `@MainActor` on `TaskStore` and `SettingsManager` — all mutations on main thread
- `AppDelegate` manages the `HotKey` object; re-call `setupHotKey()` after toggling the preference
- `DooApp.onChange(of: settings.*FilePath)` calls `store.updatePaths` to swap file watchers live
- `TaskStore.shutdown()` stops file watchers — call in test tearDown to avoid leaked DispatchSources
- `CLITaskStore` is a lightweight alternative to `TaskStore` — no file watchers, no `@Observable`, reads settings via `SettingsReader`
- `DooTask.dueDateSortKey` / `dateCompletedSortKey` — non-optional `Date` proxies used by `Table` sort (`KeyPathComparator` requires `Comparable`; `Date?` is not)
- GUI sort uses `[KeyPathComparator<DooTask>]` bound to `Table.sortOrder`; `FilterState.sortOption` is CLI-only — the GUI bypasses it
- `PipelineStatus` enum defines 4 workflow stages (untriaged → backlog → in_progress → in_review); Done remains implicit via done.json
- `PipelineStatus.fromShorthand()` normalizes various input formats (hyphens, underscores, camelCase) to enum cases
- TodoListView supports grouped (DisclosureGroup per status) and flat (Table) views, toggled via `settings.groupByStatus`
- CLI `task list` shows grouped output by default; `--status` filter or `--done` uses flat output

## CLI Skill (doo:tasks)

A Claude Code skill at `~/projects/work-tools/buckleypaul-skills/plugins/doo/skills/tasks/SKILL.md`
exposes the doo CLI as a task management tool for other workflows.

**Keep the skill in sync**: when you add or change CLI commands, flags, output format,
or inline syntax, update the skill file to match. Changes that require a skill update:
- New subcommands or flags in `Sources/DooCLILib/Commands/`
- Changes to `Sources/DooCore/Services/InlineSyntaxParser.swift` (new tokens/syntax)
- Changes to `Sources/DooCore/Models/PipelineStatus.swift` (new statuses)
- Changes to `--json` output schema (`Sources/DooCore/Models/DooTask.swift`)
