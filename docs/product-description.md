# Doo — Product Description

## Overview

Doo is a local macOS todo list management application built with Swift and SwiftUI. It stores tasks in JSON files on disk, making them easily accessible to AI tools (like Claude Code) and hand-editable in any text editor. The app provides a native macOS experience with a menu bar presence, global hotkey for quick task entry, and a full-featured main window for task management.

## Core Concepts

- **Local-first**: All data lives in JSON files on the local filesystem. No server, no sync, no account.
- **AI-tool friendly**: JSON storage format is trivially parseable by AI assistants. File paths are configurable so they can be referenced in prompts.
- **Two-file model**: Active tasks live in one file (`doo-todo.json`), completed tasks are moved to a separate file (`doo-done.json`). Both paths are configurable.
- **Live-reload**: The app watches its JSON files via FSEvents. External modifications (e.g., Claude Code editing the file) are reflected in the UI immediately.

## Data Model

### Task

```json
{
  "id": "uuid-string",
  "title": "Buy groceries",
  "description": "Weekly grocery run at Trader Joe's",
  "notes": "Don't forget the oat milk. Check if they have the seasonal items.",
  "priority": 3,
  "tags": ["personal", "errands"],
  "dueDate": "2026-03-05",
  "dateAdded": "2026-03-02T10:30:00Z",
  "dateCompleted": null,
  "subtasks": [
    {
      "id": "uuid-string",
      "title": "Make shopping list",
      "completed": false
    },
    {
      "id": "uuid-string",
      "title": "Check pantry",
      "completed": true
    }
  ]
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID string | Yes | Unique identifier, auto-generated |
| `title` | String | Yes | Short task name, displayed in list rows |
| `description` | String | No | One-line summary, visible in the list row or on expand |
| `notes` | String | No | Longer context, details, or additional information |
| `priority` | Integer (1-5) | Yes | 1 = highest, 5 = lowest. Default: 3 |
| `tags` | String array | No | Freeform tags for categorization and filtering |
| `dueDate` | ISO 8601 date | No | Optional due date. Enables overdue highlighting |
| `dateAdded` | ISO 8601 datetime | Yes | Auto-populated on creation |
| `dateCompleted` | ISO 8601 datetime | No | Populated when task is completed (moved to done file) |
| `subtasks` | Array of subtask objects | No | Optional child tasks (one level deep, no further nesting) |

### Subtask

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID string | Yes | Unique identifier |
| `title` | String | Yes | Subtask name |
| `completed` | Boolean | Yes | Completion state |

### File Structure

**doo-todo.json** (active tasks):
```json
{
  "tasks": [ /* array of Task objects */ ]
}
```

**doo-done.json** (completed tasks):
```json
{
  "tasks": [ /* array of Task objects with dateCompleted populated */ ]
}
```

When a task is checked off:
1. `dateCompleted` is set to the current datetime
2. The task (with all metadata preserved) is appended to `doo-done.json`
3. The task is removed from `doo-todo.json`
4. Both files are written atomically

## User Interface

### Main Window

The main window uses a dense, information-rich layout with two pages accessible via a tab bar or sidebar:

#### Todo Page
- Each task is a row showing: checkbox, priority badge (colored by level), title, description preview, tags as pills, due date, and date added
- Overdue tasks are visually highlighted (e.g., red due date text)
- Clicking a checkbox completes the task (animated removal, moved to done file)
- Rows are expandable to show/edit full details: description, notes, tags, priority, due date
- Sub-tasks display under their parent row with a progress indicator (e.g., "2/5")
- Sub-tasks are expandable/collapsible

**Sorting options** (selectable via toolbar):
- Priority (highest first)
- Date added (newest/oldest first)
- Due date (soonest first)
- Alphabetical

**Filtering**:
- By tag (multi-select)
- By priority range
- Overdue only toggle

**Search**:
- Fuzzy search bar that matches across title, description, notes, and tags
- Results update as you type

#### Done Page
- Same dense row layout as Todo but with checkbox replaced by a completed indicator
- Shows `dateCompleted` instead of due date
- Same sorting (by date completed, priority, date added, alphabetical), filtering, and search capabilities
- Option to move a task back to Todo (uncheck / restore)

### Quick-Add UI (Spotlight-style)

A floating, centered input panel triggered by a global hotkey.

- **Default hotkey**: Option+Space (configurable in settings)
- **Appearance**: Rounded rectangle, similar to Spotlight/Raycast, appears centered on screen with a subtle shadow
- **Input field**: Single-line text input with large font
- **Hint bar**: Small text below the input showing inline syntax:
  ```
  !1-5 priority   #tag   @date or @tomorrow   /description
  ```
- **Behavior**:
  - Enter: Creates the task and dismisses the panel
  - Escape: Dismisses without creating
  - Auto-populates `dateAdded` with current datetime
  - Priority defaults to 3 if not specified
  - Parses inline syntax from the input text

**Inline syntax examples**:
- `Buy groceries` — creates task with title "Buy groceries", priority 3
- `Buy groceries !1` — priority 1
- `Buy groceries !2 #personal #errands` — priority 2, two tags
- `Buy groceries @2026-03-05` — with due date
- `Buy groceries @tomorrow` — due date resolved to tomorrow
- `Buy groceries /Weekly run at TJs` — with description
- `Buy groceries !2 #personal @tomorrow /Weekly run` — all together

### Menu Bar

A menu bar icon (persistent) with a dropdown menu:

- **Quick Add Task**: Opens the Spotlight-style quick-add panel
- **Open Doo**: Opens/focuses the main window
- **separator**
- **Settings...**: Opens the settings/preferences window

### Settings/Preferences

A standard macOS preferences window with:

- **Todo file path**: File picker or text field. Default: `~/doo-todo.json`
- **Done file path**: File picker or text field. Default: `~/doo-done.json`
- **Global hotkey**: Hotkey recorder. Default: Option+Space
- **Launch at login**: Toggle

## Technology

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Platform**: macOS (native app)
- **File watching**: FSEvents (via `DispatchSource.makeFileSystemObjectSource` or similar)
- **File I/O**: Atomic writes to prevent corruption
- **Hotkey**: Global hotkey registration via macOS APIs (e.g., `CGEvent` tap or `MASShortcut`-style approach)
- **Distribution**: Direct download (no App Store initially, to avoid sandboxing restrictions on global hotkeys and file access)

## Non-Goals (v1)

- Cloud sync or multi-device support
- Collaboration / sharing
- Recurring tasks
- Calendar integration
- Notifications / reminders
- Task dependencies (beyond sub-tasks)
- Nested sub-tasks (only one level deep)
- Markdown rendering in notes
- App Store distribution
