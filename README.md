# Doo

A minimal, local-first todo app for macOS.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange)

Doo stores your tasks as plain JSON files on disk — no cloud account, no sync service. The file format is simple enough to read and edit by hand, and the app live-reloads whenever the files change, making it easy to manage tasks from the terminal or with tools like Claude Code.

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16+ (for building, running, and testing)

## Installation

```bash
git clone https://github.com/buckleypaul/doo
cd doo
./build-app.sh
```

This builds a release binary and assembles a proper `.app` bundle at `/Applications/Doo.app`.

To install the CLI:

```bash
sudo cp .build/release/DooCLI /usr/local/bin/doo
```

## Running

Development:

```bash
swift run
```

Release build (after running `build-app.sh`):

```bash
open /Applications/Doo.app
```

## Login Item setup

To have Doo launch at login without a Terminal window appearing:

1. Run `./build-app.sh` to create `~/Applications/Doo.app`
2. Open **System Settings → General → Login Items**
3. Remove any existing "Doo" entry that points to a Unix executable
4. Click **+** and add `/Applications/Doo.app`

## Testing

```bash
swift test                                           # run all tests
swift test --filter DooTests.InlineSyntaxParserTests # single suite
```

If `swift test` fails with "no such module 'XCTest'", your active developer tools are set to Command Line Tools instead of Xcode. Fix it with:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Or prefix test commands without changing the global setting:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Usage

### Main window

The main window has two sections in the sidebar:

- **Todo** — active tasks, with a badge showing the count
- **Done** — completed tasks

Click the **+** button in the toolbar to add a new task. Click the disclosure arrow on any row to expand it and edit the task's title, description, notes, due date, priority, and tags. Right-click a task for a context menu with **Complete** and **Delete** options.

### Menu bar

Doo runs as a menu bar app (checklist icon). The menu contains:

| Item | Shortcut |
|------|----------|
| Quick Add Task | N |
| Open Doo | O |
| Settings… | , |
| Quit Doo | Q |

### Quick Add panel

Press **Option+Space** anywhere to open the floating Quick Add panel. Type a task using inline syntax and press Return to save.

#### Syntax

```
title text [!priority] [#tag] [@date] [/description]
```

| Token | Meaning | Example |
|-------|---------|---------|
| `!N` | Priority 1–5 (1 = highest, 5 = lowest, default 3) | `!1` |
| `#tag` | One or more tags | `#work #urgent` |
| `@date` | Due date: `today`, `tomorrow`, or `yyyy-MM-dd` | `@2026-03-10` |
| `/text` | Description — everything after the `/` | `/call before noon` |

Tokens can appear in any order. Examples:

```
Buy milk #grocery @tomorrow
Fix login bug !1 #backend /check auth token expiry
Weekly review @2026-03-07 !2 #admin /go through inbox first
```

### Settings

Open Settings with **Cmd+,**. Available options:

- **Todo file path** — path to the active tasks JSON file (default: `~/.local/share/doo/todo.json`)
- **Done file path** — path to the completed tasks JSON file (default: `~/.local/share/doo/done.json`)
- **Global hotkey** — enable or disable the Option+Space Quick Add shortcut
- **Launch at login** — start Doo automatically when you log in

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| Option+Space | Toggle Quick Add panel (global) |
| Cmd+, | Open Settings |

## Data files

Tasks are stored as plain JSON files:

| File | Contents |
|------|----------|
| `~/.local/share/doo/todo.json` | Active tasks |
| `~/.local/share/doo/done.json` | Completed tasks |
| `~/.config/doo/settings.json` | App settings |

All files are created automatically on first launch. The data file paths are configurable in Settings.

### File format

```json
{
  "tasks": [
    {
      "id": "3B4F2A1C-...",
      "title": "Buy milk",
      "description": "semi-skimmed",
      "notes": "Tesco or Waitrose",
      "priority": 3,
      "tags": ["grocery"],
      "dueDate": "2026-03-10",
      "dateAdded": "2026-03-01T10:00:00Z",
      "dateCompleted": null,
      "subtasks": []
    }
  ]
}
```

`dueDate` is a date-only string (`yyyy-MM-dd`). `dateAdded` and `dateCompleted` are ISO 8601 timestamps. Optional fields (`description`, `notes`, `dueDate`, `dateCompleted`, `subtasks`) may be omitted.

## Editing tasks externally

Doo watches both JSON files for changes using filesystem events. Any external edit — from a text editor, a script, or Claude Code — is picked up automatically and reflected in the UI within a fraction of a second. You can add, modify, or remove tasks by editing the files directly, as long as the JSON remains valid.
