# Inline Add Row Design

Date: 2026-03-02

## Problem

The current "add task" flow requires two steps: click the toolbar `+` button to create a blank "New Task", then open and rename it. This is friction-heavy.

## Goal

A persistent input row pinned at the top of the Todo list where the user types a task (with optional inline syntax) and submits it with Enter or a `+` button.

## Design

### Layout

`TodoListView.body` is a `VStack`:

1. `FilterToolbar` (unchanged)
2. `Divider`
3. `InlineAddRow` — new private view
4. `Divider`
5. Existing `List` / `ContentUnavailableView`

The toolbar `+` button is removed.

### InlineAddRow

- `TextField("Add a task...", text: $newTaskInput)` with `.textFieldStyle(.plain)`
- `Button` with `plus.circle.fill` icon, `.buttonStyle(.plain)`, disabled when input is empty
- Both Return and button tap run the same action:
  1. `InlineSyntaxParser.parse(input)` → `DooTask`
  2. `store.addTask(task)`
  3. Clear input, return focus to field

### State

`@State private var newTaskInput: String = ""` lives on `TodoListView`. No changes to `TaskStore`.

### Syntax

Full inline syntax supported: `title !priority #tag @date /description`

### Tests

No new tests needed — `InlineSyntaxParser` is already covered. This is a pure UI change.
