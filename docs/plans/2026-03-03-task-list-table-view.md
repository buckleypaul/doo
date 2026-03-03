# Task List Table View Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the List+DisclosureGroup task layout with a native SwiftUI Table with sortable columns (Title, Priority, Tags, Due, Added/Completed) and a right-side `.inspector` panel for task detail.

**Architecture:** `TodoListView` and `DoneListView` switch to `Table` with a `sortOrder: [KeyPathComparator<DooTask>]` state that drives column-header sorting. Filtering continues through `FilterState.apply()` (unchanged, CLI-safe); the Table's `sortOrder` is applied on top. Task detail moves from inline DisclosureGroup to `.inspector` panel, opened by row selection.

**Tech Stack:** SwiftUI `Table`, `KeyPathComparator`, `.inspector` modifier (macOS 14+), `DooStyle` constants from `Sources/DooKit/DooStyle.swift`.

---

### Task 1: Add sort-key computed properties to DooTask

`Table` sort uses `KeyPathComparator` which requires `Comparable` values. `dueDate` and `dateCompleted` are both `Date?` (not directly comparable), so we add non-optional sort-key proxies.

**Files:**
- Modify: `Sources/DooCore/Models/DooTask.swift`
- Test: `Tests/DooTests/Models/DooTaskCodableTests.swift`

**Step 1: Write the failing tests**

Add to the bottom of `DooTaskCodableTests` (before the final `}`):

```swift
func testDueDateSortKeyReturnsDueDateWhenSet() {
    let due = dateOnly("2026-06-01")
    let task = sampleTask(title: "T", dueDate: due)
    XCTAssertEqual(task.dueDateSortKey, due)
}

func testDueDateSortKeyReturnsDistantFutureWhenNil() {
    let task = sampleTask(title: "T", dueDate: nil)
    XCTAssertEqual(task.dueDateSortKey, .distantFuture)
}

func testDateCompletedSortKeyReturnsDateCompletedWhenSet() {
    let completed = iso8601("2026-03-01T10:00:00Z")
    let task = sampleTask(title: "T", dateCompleted: completed)
    XCTAssertEqual(task.dateCompletedSortKey, completed)
}

func testDateCompletedSortKeyReturnsDistantPastWhenNil() {
    let task = sampleTask(title: "T", dateCompleted: nil)
    XCTAssertEqual(task.dateCompletedSortKey, .distantPast)
}
```

**Step 2: Run tests to verify they fail**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --filter DooTests.DooTaskCodableTests 2>&1 | grep -E "error:|FAILED|passed"
```

Expected: compile error — `value of type 'DooTask' has no member 'dueDateSortKey'`

**Step 3: Add the computed properties to DooTask**

Add at the end of `Sources/DooCore/Models/DooTask.swift`, after the closing brace of the Codable extension, as a new extension:

```swift
extension DooTask {
    /// Sort key for dueDate — nil tasks sort after dated tasks
    public var dueDateSortKey: Date { dueDate ?? .distantFuture }

    /// Sort key for dateCompleted — nil tasks sort before completed tasks
    public var dateCompletedSortKey: Date { dateCompleted ?? .distantPast }
}
```

**Step 4: Run tests to verify they pass**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --filter DooTests.DooTaskCodableTests 2>&1 | grep -E "error:|FAILED|passed"
```

Expected: `Test Suite 'DooTaskCodableTests' passed`

**Step 5: Commit**

```bash
git add Sources/DooCore/Models/DooTask.swift Tests/DooTests/Models/DooTaskCodableTests.swift
git commit -m "feat: add dueDateSortKey and dateCompletedSortKey to DooTask"
```

---

### Task 2: Remove sort Picker from FilterToolbar

The Table column headers replace the toolbar sort picker.

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/FilterToolbar.swift`

**Step 1: Remove the Picker and its helper**

In `FilterToolbar.swift`, delete these lines from `body`:

```swift
// Sort
Picker("Sort", selection: $filterState.sortOption) {
    ForEach(sortOptions, id: \.id) { option in
        Text(option.rawValue).tag(option)
    }
}
.pickerStyle(.menu)
.frame(width: 140)
```

And delete the `sortOptions` computed property at the bottom of `FilterToolbar`:

```swift
private var sortOptions: [SortOption] {
    showDateCompleted ? SortOption.allCases : SortOption.allCases.filter { $0 != .dateCompleted }
}
```

Also remove the `showDateCompleted` parameter from `FilterToolbar`'s struct declaration, init (it's implicit), and all call sites:
- `TodoListView.swift` line: `FilterToolbar(filterState: $filterState, availableTags: allTags, showDateCompleted: false)`
- `DoneListView.swift` line: `FilterToolbar(filterState: $filterState, availableTags: allTags, showDateCompleted: true)`

Both become: `FilterToolbar(filterState: $filterState, availableTags: allTags)`

**Step 2: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: `Build complete!`

**Step 3: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/FilterToolbar.swift \
        Sources/DooKit/Views/MainWindow/TodoListView.swift \
        Sources/DooKit/Views/MainWindow/DoneListView.swift
git commit -m "feat: remove sort picker from FilterToolbar (replaced by table column headers)"
```

---

### Task 3: Rewrite TodoListView with Table + inspector

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/TodoListView.swift`

**Step 1: Replace the entire file contents**

```swift
import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState()
    @State private var taskToDelete: DooTask?
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedTaskID: DooTask.ID?
    @State private var sortOrder = [KeyPathComparator(\DooTask.priority)]

    private var displayedTasks: [DooTask] {
        filterState.apply(to: store.activeTasks).sorted(using: sortOrder)
    }

    private var allTags: [String] {
        Array(Set(store.activeTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterToolbar(filterState: $filterState, availableTags: allTags)
            Divider()
            InlineAddRow(input: $newTaskInput, isFocused: $isInputFocused) {
                submitNewTask()
            }
            Divider()
            taskContent
        }
        .inspector(isPresented: Binding(
            get: { selectedTaskID != nil },
            set: { if !$0 { selectedTaskID = nil } }
        )) {
            if let id = selectedTaskID,
               let index = store.activeTasks.firstIndex(where: { $0.id == id }) {
                TaskDetailView(store: store, task: $store.activeTasks[index])
            } else {
                Text("Select a task")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .inspectorColumnWidth(min: 260, ideal: 320, max: 420)
        .alert("Delete Task?", isPresented: Binding(
            get: { taskToDelete != nil },
            set: { if !$0 { taskToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { taskToDelete = nil }
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    withAnimation { store.deleteTask(task) }
                    taskToDelete = nil
                }
            }
        } message: {
            if let task = taskToDelete {
                Text("Are you sure you want to delete \"\(task.title)\"?")
            }
        }
    }

    @ViewBuilder
    private var taskContent: some View {
        if displayedTasks.isEmpty {
            ContentUnavailableView(
                store.activeTasks.isEmpty ? "No Tasks" : "No Matches",
                systemImage: store.activeTasks.isEmpty ? "checkmark.circle" : "magnifyingglass",
                description: Text(store.activeTasks.isEmpty ? "Add a task to get started." : "Try adjusting your filters.")
            )
            .frame(maxHeight: .infinity)
        } else {
            Table(displayedTasks, selection: $selectedTaskID, sortOrder: $sortOrder) {
                TableColumn("Title", value: \.title) { task in
                    Text(task.title)
                }
                TableColumn("Priority", value: \.priority) { task in
                    let color = DooStyle.priorityColor(for: task.priority)
                    Text("P\(task.priority)")
                        .font(.caption2.weight(.bold))
                        .frame(width: DooStyle.Size.badge, height: DooStyle.Size.badge)
                        .background(color.opacity(0.2))
                        .foregroundStyle(color)
                        .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.badge))
                }
                .width(70)
                TableColumn("Tags") { task in
                    HStack(spacing: DooStyle.Spacing.xs) {
                        ForEach(task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, DooStyle.Spacing.sm - 2)
                                .padding(.vertical, DooStyle.Spacing.xs)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }
                TableColumn("Due", value: \.dueDateSortKey) { task in
                    if let due = task.dueDate {
                        Text(DateFormatting.dateOnly(due))
                            .font(.caption)
                            .foregroundStyle(DateFormatting.isOverdue(due) ? .red : .secondary)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .width(100)
                TableColumn("Added", value: \.dateAdded) { task in
                    Text(DateFormatting.relative(task.dateAdded))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .width(90)
            }
            .contextMenu(forSelectionType: DooTask.ID.self) { ids in
                if let id = ids.first,
                   let task = store.activeTasks.first(where: { $0.id == id }) {
                    Button("Complete") {
                        withAnimation { store.completeTask(task) }
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        taskToDelete = task
                    }
                }
            }
            .onChange(of: store.activeTasks) { _, tasks in
                if let id = selectedTaskID, !tasks.contains(where: { $0.id == id }) {
                    selectedTaskID = nil
                }
            }
        }
    }

    private func submitNewTask() {
        let trimmed = newTaskInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let task = InlineSyntaxParser.parse(trimmed)
        withAnimation { store.addTask(task) }
        newTaskInput = ""
        isInputFocused = true
    }
}

private struct InlineAddRow: View {
    @Binding var input: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    private var isInputEmpty: Bool {
        input.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
            HStack(spacing: DooStyle.Spacing.sm) {
                TextField("Add a task...", text: $input)
                    .textFieldStyle(.plain)
                    .focused(isFocused)
                    .onSubmit { onSubmit() }

                Button(action: onSubmit) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: DooStyle.Size.badge))
                        .foregroundStyle(isInputEmpty ? Color.secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(isInputEmpty)
            }

            HStack(spacing: DooStyle.Spacing.lg) {
                hintItem("!0-2", label: "priority")
                hintItem("#tag", label: "tag")
                hintItem("@today", label: "or @tomorrow")
                hintItem("/text", label: "description")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DooStyle.Spacing.lg)
        .padding(.vertical, DooStyle.Spacing.sm)
    }

    private func hintItem(_ code: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(code)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(label)
        }
    }
}
```

**Step 2: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: `Build complete!`

**Step 3: Run tests**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | tail -5
```

Expected: `Executed 148 tests, with 0 failures`

**Step 4: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/TodoListView.swift
git commit -m "feat: replace TodoListView List with Table and inspector panel"
```

---

### Task 4: Rewrite DoneListView with Table + inspector

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/DoneListView.swift`

**Step 1: Replace the entire file contents**

```swift
import SwiftUI

struct DoneListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState(sortOption: .dateCompleted)
    @State private var taskToDelete: DooTask?
    @State private var selectedTaskID: DooTask.ID?
    @State private var sortOrder = [KeyPathComparator(\DooTask.dateCompletedSortKey, order: .reverse)]

    private var displayedTasks: [DooTask] {
        filterState.apply(to: store.completedTasks).sorted(using: sortOrder)
    }

    private var allTags: [String] {
        Array(Set(store.completedTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterToolbar(filterState: $filterState, availableTags: allTags)
            Divider()
            taskContent
        }
        .inspector(isPresented: Binding(
            get: { selectedTaskID != nil },
            set: { if !$0 { selectedTaskID = nil } }
        )) {
            if let id = selectedTaskID,
               let index = store.completedTasks.firstIndex(where: { $0.id == id }) {
                TaskDetailView(store: store, task: $store.completedTasks[index])
            } else {
                Text("Select a task")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .inspectorColumnWidth(min: 260, ideal: 320, max: 420)
        .alert("Delete Task?", isPresented: Binding(
            get: { taskToDelete != nil },
            set: { if !$0 { taskToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { taskToDelete = nil }
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    withAnimation { store.deleteTask(task) }
                    taskToDelete = nil
                }
            }
        } message: {
            if let task = taskToDelete {
                Text("Are you sure you want to delete \"\(task.title)\"?")
            }
        }
    }

    @ViewBuilder
    private var taskContent: some View {
        if displayedTasks.isEmpty {
            ContentUnavailableView(
                store.completedTasks.isEmpty ? "No Completed Tasks" : "No Matches",
                systemImage: store.completedTasks.isEmpty ? "tray" : "magnifyingglass",
                description: Text(store.completedTasks.isEmpty ? "Completed tasks will appear here." : "Try adjusting your filters.")
            )
            .frame(maxHeight: .infinity)
        } else {
            Table(displayedTasks, selection: $selectedTaskID, sortOrder: $sortOrder) {
                TableColumn("Title", value: \.title) { task in
                    Text(task.title)
                        .foregroundStyle(.secondary)
                }
                TableColumn("Priority", value: \.priority) { task in
                    let color = DooStyle.priorityColor(for: task.priority)
                    Text("P\(task.priority)")
                        .font(.caption2.weight(.bold))
                        .frame(width: DooStyle.Size.badge, height: DooStyle.Size.badge)
                        .background(color.opacity(0.2))
                        .foregroundStyle(color)
                        .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.badge))
                }
                .width(70)
                TableColumn("Tags") { task in
                    HStack(spacing: DooStyle.Spacing.xs) {
                        ForEach(task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, DooStyle.Spacing.sm - 2)
                                .padding(.vertical, DooStyle.Spacing.xs)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }
                TableColumn("Due", value: \.dueDateSortKey) { task in
                    if let due = task.dueDate {
                        Text(DateFormatting.dateOnly(due))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .width(100)
                TableColumn("Completed", value: \.dateCompletedSortKey) { task in
                    if let completed = task.dateCompleted {
                        Text(DateFormatting.relative(completed))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(110)
            }
            .contextMenu(forSelectionType: DooTask.ID.self) { ids in
                if let id = ids.first,
                   let task = store.completedTasks.first(where: { $0.id == id }) {
                    Button("Restore to Todo") {
                        withAnimation { store.uncompleteTask(task) }
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        taskToDelete = task
                    }
                }
            }
            .onChange(of: store.completedTasks) { _, tasks in
                if let id = selectedTaskID, !tasks.contains(where: { $0.id == id }) {
                    selectedTaskID = nil
                }
            }
        }
    }
}
```

**Step 2: Build to verify**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: `Build complete!`

**Step 3: Run tests**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | tail -5
```

Expected: `Executed 148 tests, with 0 failures`

**Step 4: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/DoneListView.swift
git commit -m "feat: replace DoneListView List with Table and inspector panel"
```

---

### Task 5: Delete TaskRowView

`TaskRowView` is no longer referenced by any view now that both list views use `Table`.

**Files:**
- Delete: `Sources/DooKit/Views/MainWindow/TaskRowView.swift`

**Step 1: Verify it has no remaining references**

```bash
grep -r "TaskRowView" Sources/ Tests/
```

Expected: no output (zero matches).

**Step 2: Delete the file**

```bash
git rm Sources/DooKit/Views/MainWindow/TaskRowView.swift
```

**Step 3: Build and test**

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build 2>&1 | grep -E "error:|Build complete"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test 2>&1 | tail -5
```

Expected: `Build complete!` and `Executed 148 tests, with 0 failures`

**Step 4: Commit**

```bash
git commit -m "chore: delete TaskRowView (replaced by Table columns)"
```

---

## Verification

```bash
# Full test suite
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test

# Visual check
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift run Doo
```

Visual checks:
- Todo and Done views show a table with Title / Priority / Tags / Due / Added(or Completed) columns
- Clicking a column header sorts the list; chevron shows sort direction
- Tags column is not sortable (no chevron, no sort indicator when clicked)
- Clicking a row opens the task detail in a right-side inspector panel
- Clicking the selected row or pressing Escape closes the inspector
- Right-clicking a row shows "Complete" / "Delete" (Todo) or "Restore to Todo" / "Delete" (Done)
- Completing a task from the inspector (via a field change) removes it from Todo and clears selection
- Quick-add row and filter toolbar above the table continue to work
