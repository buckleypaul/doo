import AppKit
import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore
    @Bindable var settings: SettingsManager
    @State private var filterState = FilterState()
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedTaskID: DooTask.ID?
    @State private var sortOrder = [KeyPathComparator(\DooTask.priority)]
    @State private var showDetail = true
    @State private var savedDetailWidth: CGFloat = 320
    @State private var dragStartWidth: CGFloat? = nil
    @State private var expandedSections: Set<PipelineStatus> = Set(PipelineStatus.allCases)
    @State private var hoveredTaskID: DooTask.ID?

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
                DooStyle.separator
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
                Button {
                    settings.groupByStatus.toggle()
                } label: {
                    Image(systemName: settings.groupByStatus ? "rectangle.3.group" : "list.bullet")
                }
                .help(settings.groupByStatus ? "Switch to Flat View" : "Switch to Grouped View")
            }
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
                    .foregroundStyle(DooStyle.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(DooStyle.surface)
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
        } else if settings.groupByStatus {
            groupedView
        } else {
            flatTableView
        }
    }

    @ViewBuilder
    private var groupedView: some View {
        let tasks = displayedTasks
        let grouped = Dictionary(grouping: tasks, by: \.status)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(PipelineStatus.allCases) { status in
                    let sectionTasks = grouped[status, default: []]
                    sectionHeader(status, count: sectionTasks.count)
                    if expandedSections.contains(status) {
                        ForEach(sectionTasks) { task in
                            groupedTaskRow(task)
                        }
                    }
                    Spacer().frame(height: 16)
                }
            }
            .padding(.horizontal, DooStyle.Spacing.md)
            .padding(.vertical, DooStyle.Spacing.sm)
        }
    }

    private func sectionHeader(_ status: PipelineStatus, count: Int) -> some View {
        let expanded = expandedSections.contains(status)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: DooStyle.Spacing.sm) {
                Text(status.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DooStyle.textSecondary)
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, DooStyle.Spacing.sm - 2)
                    .padding(.vertical, 2)
                    .background(DooStyle.tagBg)
                    .clipShape(Capsule())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DooStyle.textSecondary)
                    .rotationEffect(expanded ? .degrees(90) : .zero)
                    .animation(.easeInOut(duration: 0.15), value: expanded)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if expanded {
                        expandedSections.remove(status)
                    } else {
                        expandedSections.insert(status)
                    }
                }
            }
            .padding(.vertical, DooStyle.Spacing.xs)
            Divider()
        }
    }

    private func groupedTaskRow(_ task: DooTask) -> some View {
        let isSelected = selectedTaskID == task.id
        let isHovered = hoveredTaskID == task.id
        return taskRow(task)
            .padding(.horizontal, DooStyle.Spacing.sm)
            .padding(.vertical, DooStyle.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DooStyle.Radius.card)
                    .fill(isSelected ? DooStyle.accent.opacity(0.1) : isHovered ? DooStyle.tagBg.opacity(0.6) : .clear)
            )
            .contentShape(Rectangle())
            .onTapGesture { selectedTaskID = task.id }
            .onHover { hovering in hoveredTaskID = hovering ? task.id : nil }
            .contextMenu { taskContextMenu(task) }
    }

    private func taskRow(_ task: DooTask) -> some View {
        HStack(spacing: DooStyle.Spacing.sm) {
            CompleteButtonCell(isCompleted: false) {
                store.completeTask(task)
            }
            Text(task.title)
                .lineLimit(1)
            Spacer()
            PriorityBadge(priority: task.priority)
            if !task.tags.isEmpty {
                HStack(spacing: 2) {
                    ForEach(task.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, DooStyle.Spacing.sm - 2)
                            .padding(.vertical, DooStyle.Spacing.xs)
                            .background(DooStyle.tagBg)
                            .clipShape(Capsule())
                    }
                }
            }
            if let due = task.dueDate {
                Text(DateFormatting.dateOnly(due))
                    .font(.caption)
                    .foregroundStyle(DateFormatting.isOverdue(due) ? DooStyle.colorRed : DooStyle.textSecondary)
            }
            DeleteButtonCell(
                onDelete: { withAnimation { store.deleteTask(task) } }
            )
        }
    }

    @ViewBuilder
    private func taskContextMenu(_ task: DooTask) -> some View {
        Button("Complete") {
            withAnimation { store.completeTask(task) }
        }
        Divider()
        Menu("Move to") {
            ForEach(PipelineStatus.allCases) { status in
                if status != task.status {
                    Button(status.displayName) {
                        var updated = task
                        updated.status = status
                        store.updateTask(updated)
                    }
                }
            }
        }
        Divider()
        Button("Delete", role: .destructive) {
            withAnimation { store.deleteTask(task) }
        }
    }

    @ViewBuilder
    private var flatTableView: some View {
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
            TableColumn("Status") { task in
                Text(task.status.displayName)
                    .font(.caption)
                    .tableCell()
            }
            .width(90)
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
                            .background(DooStyle.tagBg)
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
                            .foregroundStyle(DateFormatting.isOverdue(due) ? DooStyle.colorRed : DooStyle.textSecondary)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(DooStyle.textTertiary)
                    }
                }
                .tableCell()
            }
            .width(100)
            TableColumn("Added", value: \.dateAdded) { task in
                Text(DateFormatting.relative(task.dateAdded))
                    .font(.caption)
                    .foregroundStyle(DooStyle.textSecondary)
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
                taskContextMenu(task)
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
                        .foregroundStyle(isInputEmpty ? DooStyle.textSecondary : DooStyle.accent)
                }
                .buttonStyle(.plain)
                .disabled(isInputEmpty)
            }

            HStack(spacing: DooStyle.Spacing.lg) {
                hintItem("!0-2", label: "priority")
                hintItem("#tag", label: "tag")
                hintItem("@today", label: "or @tomorrow")
                hintItem("%status", label: "pipeline")
                hintItem("/text", label: "description")
            }
            .font(.caption)
            .foregroundStyle(DooStyle.textTertiary)
        }
        .padding(.horizontal, DooStyle.Spacing.lg)
        .padding(.vertical, DooStyle.Spacing.sm)
    }

    private func hintItem(_ code: String, label: String) -> some View {
        HStack(spacing: 2) {
            Text(code)
                .fontWeight(.medium)
                .foregroundStyle(DooStyle.textSecondary)
            Text(label)
        }
    }
}
