# Task List Table View — Design

Date: 2026-03-03

## Problem

Task list rows show priority, tags, and dates but they're layered vertically with no column alignment. There's no way to sort by clicking a field — sort is only available via a toolbar picker. The inline DisclosureGroup detail expansion is awkward with many tasks.

## Approach

Replace the `List` + `DisclosureGroup` layout in `TodoListView` and `DoneListView` with a native SwiftUI `Table`. Task detail moves to a right-side `.inspector` panel that opens when a row is selected. Column headers are clickable to sort.

## Layout

```
┌─ sidebar ──┬─ table ──────────────────────┬─ inspector ──┐
│ Todo       │ Title    Pri  Tags  Due  Added│ [TaskDetail] │
│ Done       │ ─────────────────────────────│              │
│ Settings   │ Fix bug   P0   #be  Mar 5 2d │ Title: ...   │
│            │ Buy milk  P1   #gr  —    1d  │ Priority: P0 │
│            │ ...                          │ Tags: ...    │
└────────────┴──────────────────────────────┴──────────────┘
```

## Table Columns

| Column | Width | Sortable | Display |
|--------|-------|----------|---------|
| Title | flexible | yes (`\.title`) | plain text |
| Priority | 70pt | yes (`\.priority`) | P0/P1/P2 badge |
| Tags | flexible | no | pills |
| Due | 100pt | yes (`dueDateSortKey`) | formatted date or `—` |
| Added | 90pt | yes (`\.dateAdded`) | relative date |

Default sort: priority ascending (same as today).

Tags are not sortable — multi-value fields have no meaningful single sort key.

## Sort State

Each list view holds `@State private var sortOrder: [KeyPathComparator<DooTask>]`.
Data flow:
1. `filterState.apply(to: store.tasks)` — filtering only (sort in apply() is bypassed in GUI)
2. `.sorted(using: sortOrder)` — table sort applied after filtering
3. Result passed to `Table`

`FilterState` is unchanged — the CLI continues to use its sort enum.

## Inspector / Detail Panel

- `@State private var selectedTaskID: DooTask.ID?` tracks selection
- `.inspector(isPresented:)` shows `TaskDetailView` for the selected task
- Inspector width: min 260, ideal 320, max 420
- Clicking a selected row deselects and closes the inspector
- If selected task disappears from list (completed/deleted), selection clears automatically
- `TaskDetailView` is unchanged

## FilterToolbar

Sort `Picker` removed — column headers replace it. Search, priority pills, tag filter, and overdue pill remain.

## Files Changed

| File | Change |
|------|--------|
| `Sources/DooCore/Models/DooTask.swift` | Add `dueDateSortKey: Date` computed property |
| `Sources/DooKit/Views/MainWindow/TodoListView.swift` | Replace List with Table, add inspector, add sortOrder state |
| `Sources/DooKit/Views/MainWindow/DoneListView.swift` | Same as TodoListView |
| `Sources/DooKit/Views/MainWindow/FilterToolbar.swift` | Remove sort Picker |
| `Sources/DooKit/Views/MainWindow/TaskRowView.swift` | Delete (no longer used) |
| `Tests/DooTests/Models/DooTaskCodableTests.swift` | Add tests for dueDateSortKey |

No changes to: `FilterState.swift`, `TaskDetailView.swift`, `ContentView.swift`, `DooStyle.swift`.
