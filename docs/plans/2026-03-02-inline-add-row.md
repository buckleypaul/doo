# Inline Add Row Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the toolbar "+" button with a persistent input row at the top of the Todo list that parses inline syntax and adds tasks on Enter or button click.

**Architecture:** Add a private `InlineAddRow` view inside `TodoListView` that holds `@State private var newTaskInput: String`. On submit it calls `InlineSyntaxParser.parse(input)` then `store.addTask(...)`. The toolbar button is removed.

**Tech Stack:** SwiftUI, `InlineSyntaxParser` (already in `DooCore`), `TaskStore` (already injected into `TodoListView`).

---

### Task 1: Remove toolbar button and add persistent input row

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/TodoListView.swift`

**Step 1: Read the current file**

Read `Sources/DooKit/Views/MainWindow/TodoListView.swift` to confirm current state before editing.

**Step 2: Add `@State` for draft input and replace toolbar with inline row**

Replace the entire file content with the following:

```swift
import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState()
    @State private var taskToDelete: DooTask?
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool

    private var filteredTasks: [DooTask] {
        filterState.apply(to: store.activeTasks)
    }

    private var allTags: [String] {
        Array(Set(store.activeTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterToolbar(filterState: $filterState, availableTags: allTags, showDateCompleted: false)

            Divider()

            InlineAddRow(input: $newTaskInput, isFocused: $isInputFocused) {
                submitNewTask()
            }

            Divider()

            if filteredTasks.isEmpty {
                ContentUnavailableView(
                    store.activeTasks.isEmpty ? "No Tasks" : "No Matches",
                    systemImage: store.activeTasks.isEmpty ? "checkmark.circle" : "magnifyingglass",
                    description: Text(store.activeTasks.isEmpty ? "Add a task to get started." : "Try adjusting your filters.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        if let index = store.activeTasks.firstIndex(where: { $0.id == task.id }) {
                            DisclosureGroup {
                                TaskDetailView(store: store, task: $store.activeTasks[index])
                            } label: {
                                TaskRowView(task: task) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        store.completeTask(task)
                                    }
                                }
                            }
                            .contextMenu {
                                Button("Complete") {
                                    withAnimation { store.completeTask(task) }
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    taskToDelete = task
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let task = filteredTasks[index]
                            taskToDelete = task
                        }
                    }
                }
            }
        }
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

    private func submitNewTask() {
        let trimmed = newTaskInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let task = InlineSyntaxParser.parse(trimmed)
        withAnimation {
            store.addTask(task)
        }
        newTaskInput = ""
        isInputFocused = true
    }
}

private struct InlineAddRow: View {
    @Binding var input: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Add a task...", text: $input)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .onSubmit { onSubmit() }

            Button(action: onSubmit) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(input.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
```

**Step 3: Build to confirm no compile errors**

```bash
swift build 2>&1 | head -40
```

Expected: `Build complete!` with no errors.

**Step 4: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/TodoListView.swift
git commit -m "feat: replace toolbar add button with persistent inline add row"
```

---

### Task 2: Verify inline syntax hint is discoverable (optional UX polish)

The QuickAdd panel shows syntax hints (`!1-5`, `#tag`, `@date`, `/description`) below its field. The inline row doesn't need them (it would clutter the list), but a `placeholder` showing the syntax is enough.

**Files:**
- Modify: `Sources/DooKit/Views/MainWindow/TodoListView.swift` (only the `TextField` placeholder)

**Step 1: Update placeholder text**

In `InlineAddRow`, change:
```swift
TextField("Add a task...", text: $input)
```
to:
```swift
TextField("Add a task... (!priority #tag @date /desc)", text: $input)
```

**Step 2: Build**

```bash
swift build 2>&1 | head -40
```

Expected: `Build complete!`

**Step 3: Commit**

```bash
git add Sources/DooKit/Views/MainWindow/TodoListView.swift
git commit -m "feat: show inline syntax hint in add row placeholder"
```

---

### Task 3: Run full test suite to confirm nothing is broken

**Step 1: Run tests**

```bash
swift test 2>&1 | tail -20
```

Expected: All tests pass (`Test Suite 'All tests' passed`). No new tests are needed — `InlineSyntaxParser` is already fully tested and this change is purely UI with no new logic.

**Step 2: Commit if any incidental fixes were needed; otherwise done**
