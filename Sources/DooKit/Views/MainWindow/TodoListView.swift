import AppKit
import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState()
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedTaskID: DooTask.ID?
    @State private var sortOrder = [KeyPathComparator(\DooTask.priority)]
    @State private var showDetail = true
    @State private var savedDetailWidth: CGFloat = 320
    @State private var dragStartWidth: CGFloat? = nil

    private var displayedTasks: [DooTask] {
        filterState.apply(to: store.activeTasks).sorted(using: sortOrder)
    }

    private var allTags: [String] {
        Array(Set(store.activeTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                FilterToolbar(filterState: $filterState, availableTags: allTags)
                Divider()
                InlineAddRow(input: $newTaskInput, isFocused: $isInputFocused) {
                    submitNewTask()
                }
                Divider()
                taskContent
            }
            .frame(minWidth: 300, maxWidth: .infinity)

            if showDetail {
                Color(nsColor: .separatorColor)
                    .frame(width: 1)
                    .frame(width: 9)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                if dragStartWidth == nil { dragStartWidth = savedDetailWidth }
                                savedDetailWidth = max(220, min(700, (dragStartWidth ?? savedDetailWidth) - value.translation.width))
                            }
                            .onEnded { _ in dragStartWidth = nil }
                    )

                detailPanel
                    .frame(width: savedDetailWidth)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showDetail.toggle() } label: {
                    Image(systemName: "sidebar.right")
                }
                .help("Toggle Detail Panel")
            }
        }
        .onChange(of: store.activeTasks) { _, tasks in
            if let id = selectedTaskID, !tasks.contains(where: { $0.id == id }) {
                selectedTaskID = nil
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        VStack(spacing: 0) {
            if let id = selectedTaskID,
               let index = store.activeTasks.firstIndex(where: { $0.id == id }) {
                TaskDetailView(store: store, task: $store.activeTasks[index])
            } else {
                Text("Select a task")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(SidebarMaterial())
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
            Table(displayedTasks, selection: Binding(
                get: { selectedTaskID },
                set: { if let id = $0 { selectedTaskID = id } }
            ), sortOrder: $sortOrder) {
                TableColumn("") { task in
                    CompleteButtonCell(isCompleted: false) {
                        store.completeTask(task)
                    }
                    .tableCell(alignment: .center)
                }
                .width(DooStyle.Size.icon + DooStyle.Spacing.sm)
                TableColumn("Title", value: \.title) { task in
                    Text(task.title)
                        .tableCell()
                }
                TableColumn("Priority", value: \.priority) { task in
                    PriorityBadge(priority: task.priority)
                        .tableCell(alignment: .center)
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
                    .tableCell()
                }
                TableColumn("Due", value: \.dueDateSortKey) { task in
                    Group {
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
                    .tableCell()
                }
                .width(100)
                TableColumn("Added", value: \.dateAdded) { task in
                    Text(DateFormatting.relative(task.dateAdded))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .tableCell()
                }
                .width(90)
                TableColumn("") { task in
                    DeleteButtonCell(
                        onDelete: { withAnimation { store.deleteTask(task) } }
                    )
                    .tableCell(alignment: .center)
                }
                .width(min: 24, ideal: 64, max: 64)
            }
            .contextMenu(forSelectionType: DooTask.ID.self) { ids in
                if let id = ids.first,
                   let task = store.activeTasks.first(where: { $0.id == id }) {
                    Button("Complete") {
                        withAnimation { store.completeTask(task) }
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        withAnimation { store.deleteTask(task) }
                    }
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
