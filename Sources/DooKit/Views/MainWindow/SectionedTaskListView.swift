import AppKit
import SwiftUI

private struct RowKey: Hashable {
    let sectionID: UUID
    let taskID: DooTask.ID
}

struct SectionedTaskListView: View {
    @Bindable var store: TaskStore
    @Bindable var settings: SettingsManager
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedTaskID: DooTask.ID?
    @State private var expandedTaskIDs: Set<DooTask.ID> = []
    @State private var editorSectionID: UUID?
    @State private var tagPopoverKey: RowKey?
    @State private var statusPopoverKey: RowKey?
    @State private var priorityPopoverKey: RowKey?
    @State private var dueDatePopoverKey: RowKey?
    @State private var hoveredRowKey: RowKey?
    @State private var editingTitleKey: RowKey?
    @State private var editingTitleText: String = ""
    @FocusState private var focusedTitleTaskID: DooTask.ID?

    // Shared resizable column widths (persisted across sections)
    @State private var statusWidth: CGFloat = 90
    @State private var priorityWidth: CGFloat = 60
    @State private var tagsWidth: CGFloat = 160
    @State private var dueWidth: CGFloat = 90
    @State private var addedWidth: CGFloat = 80

    private let checkWidth: CGFloat = 28
    private let deleteWidth: CGFloat = 40
    private let chevronWidth: CGFloat = 20

    private var sortedSections: [TaskSection] {
        settings.sections.sorted { $0.order < $1.order }
    }

    private var allTags: [String] {
        Array(Set(store.activeTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            InlineAddRow(input: $newTaskInput, isFocused: $isInputFocused) {
                submitNewTask()
            }
            Divider()
            sectionContent
        }
        .frame(minWidth: 300, maxWidth: .infinity)
        .onChange(of: focusedTitleTaskID) { oldValue, newValue in
            if let taskID = oldValue, newValue == nil {
                saveTitleEdit(taskID: taskID)
                editingTitleKey = nil
            }
        }
        .onChange(of: store.activeTasks) { _, tasks in
            if let id = selectedTaskID, !tasks.contains(where: { $0.id == id }) {
                selectedTaskID = nil
            }
            expandedTaskIDs = expandedTaskIDs.filter { id in
                tasks.contains(where: { $0.id == id })
            }
        }
    }

    // MARK: - Per-section column header

    private func sectionColumnHeader(_ section: TaskSection) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: chevronWidth)
            Spacer().frame(width: checkWidth)
            sortHeaderButton("Title", column: "title", section: section)
                .frame(maxWidth: .infinity, alignment: .leading)
            ColumnResizeHandle(rightWidth: $statusWidth)
            sortHeaderButton("Status", column: "status", section: section)
                .frame(width: statusWidth, alignment: .leading)
            ColumnResizeHandle(rightWidth: $priorityWidth)
            sortHeaderButton("Priority", column: "priority", section: section)
                .frame(width: priorityWidth, alignment: .center)
            ColumnResizeHandle(rightWidth: $tagsWidth)
            sortHeaderButton("Tags", column: "tags", section: section)
                .frame(width: tagsWidth, alignment: .leading)
            ColumnResizeHandle(rightWidth: $dueWidth)
            sortHeaderButton("Due", column: "dueDate", section: section)
                .frame(width: dueWidth, alignment: .leading)
            ColumnResizeHandle(rightWidth: $addedWidth)
            sortHeaderButton("Added", column: "dateAdded", section: section)
                .frame(width: addedWidth, alignment: .leading)
            Spacer().frame(width: deleteWidth)
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(.caption)
        .foregroundStyle(DooStyle.textSecondary)
        .padding(.horizontal, DooStyle.Spacing.md)
        .padding(.vertical, DooStyle.Spacing.xs)
        .background(DooStyle.surface)
    }

    private func sortHeaderButton(_ label: String, column: String, section: TaskSection) -> some View {
        let isActive = section.sortColumn == column
        return Button { toggleSort(column: column, in: section) } label: {
            HStack(spacing: 2) {
                Text(label)
                if isActive {
                    Image(systemName: section.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                } else {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7))
                        .foregroundStyle(DooStyle.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section content

    @ViewBuilder
    private var sectionContent: some View {
        if store.activeTasks.isEmpty && settings.sections.allSatisfy({ tasksForSection($0).isEmpty }) {
            ContentUnavailableView(
                "No Tasks",
                systemImage: "checkmark.circle",
                description: Text("Add a task to get started.")
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sortedSections) { section in
                        sectionView(section)
                    }
                }
                .padding(.vertical, DooStyle.Spacing.sm)

                Button {
                    settings.addSection(name: "New Section")
                } label: {
                    HStack(spacing: DooStyle.Spacing.xs) {
                        Image(systemName: "plus.circle")
                            .font(.caption)
                        Text("Add Section")
                            .font(.caption)
                    }
                    .foregroundStyle(DooStyle.textSecondary)
                    .padding(.horizontal, DooStyle.Spacing.md)
                    .padding(.vertical, DooStyle.Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Single section

    @ViewBuilder
    private func sectionView(_ section: TaskSection) -> some View {
        let tasks = tasksForSection(section)

        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: DooStyle.Spacing.sm) {
                Text(section.name.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DooStyle.textSecondary)
                Text("\(tasks.count)")
                    .font(.caption2)
                    .padding(.horizontal, DooStyle.Spacing.sm - 2)
                    .padding(.vertical, 2)
                    .background(DooStyle.tagBg)
                    .clipShape(Capsule())
                Spacer()

                Button {
                    if editorSectionID == section.id {
                        editorSectionID = nil
                    } else {
                        editorSectionID = section.id
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textSecondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { editorSectionID == section.id },
                    set: { if !$0 { editorSectionID = nil } }
                )) {
                    SectionEditorPopover(
                        section: section,
                        availableTags: allTags,
                        canDelete: settings.sections.count > 1,
                        onUpdate: { updated in
                            settings.updateSection(updated)
                        },
                        onDelete: {
                            settings.removeSection(id: section.id)
                        }
                    )
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DooStyle.textSecondary)
                    .rotationEffect(section.isCollapsed ? .zero : .degrees(90))
                    .animation(.easeInOut(duration: 0.15), value: section.isCollapsed)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    var updated = section
                    updated.isCollapsed.toggle()
                    settings.updateSection(updated)
                }
            }
            .padding(.horizontal, DooStyle.Spacing.md)
            .padding(.vertical, DooStyle.Spacing.xs)
            .draggable(section.id.uuidString) {
                Text(section.name)
                    .padding(DooStyle.Spacing.sm)
                    .background(DooStyle.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.card))
            }
            .dropDestination(for: String.self) { items, _ in
                guard let droppedIDString = items.first,
                      let droppedID = UUID(uuidString: droppedIDString),
                      droppedID != section.id,
                      let fromIndex = settings.sections.firstIndex(where: { $0.id == droppedID }),
                      let toIndex = settings.sections.firstIndex(where: { $0.id == section.id })
                else { return false }
                settings.moveSections(from: IndexSet(integer: fromIndex), to: toIndex > fromIndex ? toIndex + 1 : toIndex)
                return true
            }

            Divider()
                .padding(.horizontal, DooStyle.Spacing.md)

            if !section.isCollapsed {
                sectionColumnHeader(section)
                Divider()
                    .padding(.horizontal, DooStyle.Spacing.md)
                if tasks.isEmpty {
                    Text("No matching tasks")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textTertiary)
                        .padding(.horizontal, DooStyle.Spacing.md)
                        .padding(.vertical, DooStyle.Spacing.sm)
                } else {
                    ForEach(tasks) { task in
                        taskRow(task, section: section)
                    }
                }
            }

            Spacer().frame(height: DooStyle.Spacing.md)
        }
    }

    // MARK: - Task row (tabular)

    private func taskRow(_ task: DooTask, section: TaskSection) -> some View {
        let key = RowKey(sectionID: section.id, taskID: task.id)
        let isSelected = selectedTaskID == task.id
        let isHovered = hoveredRowKey?.taskID == task.id
        let isExpanded = expandedTaskIDs.contains(task.id)
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Chevron
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isExpanded {
                            expandedTaskIDs.remove(task.id)
                        } else {
                            expandedTaskIDs.insert(task.id)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textSecondary)
                        .rotationEffect(isExpanded ? .degrees(90) : .zero)
                        .animation(.easeInOut(duration: 0.15), value: isExpanded)
                }
                .buttonStyle(.plain)
                .frame(width: chevronWidth, alignment: .center)

                // Check
                CompleteButtonCell(isCompleted: false) {
                    store.completeTask(task)
                }
                .frame(width: checkWidth, alignment: .center)

                // Title (flexible) — click to edit inline
                if editingTitleKey == key {
                    TextField("Title", text: $editingTitleText, axis: .vertical)
                        .lineLimit(1...8)
                        .textFieldStyle(.plain)
                        .focused($focusedTitleTaskID, equals: task.id)
                        .onSubmit { saveTitleEdit(taskID: task.id) }
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(task.title)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            if let prevKey = editingTitleKey, prevKey != key {
                                saveTitleEdit(taskID: prevKey.taskID)
                            }
                            selectedTaskID = task.id
                            editingTitleKey = key
                            editingTitleText = task.title
                            focusedTitleTaskID = task.id
                        }
                }

                Spacer().frame(width: 7) // match header divider width

                // Status
                Button {
                    statusPopoverKey = key
                } label: {
                    Text(task.status.displayName)
                        .font(.caption)
                        .foregroundStyle(DooStyle.textSecondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { statusPopoverKey == key },
                    set: { if !$0 { statusPopoverKey = nil } }
                )) {
                    InlineStatusEditor(task: task, store: store)
                }
                .frame(width: statusWidth, alignment: .leading)

                Spacer().frame(width: 7)

                // Priority
                Button {
                    priorityPopoverKey = key
                } label: {
                    PriorityBadge(priority: task.priority)
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { priorityPopoverKey == key },
                    set: { if !$0 { priorityPopoverKey = nil } }
                )) {
                    InlinePriorityEditor(task: task, store: store)
                }
                .frame(width: priorityWidth, alignment: .center)

                Spacer().frame(width: 7)

                // Tags
                HStack(spacing: 2) {
                    ForEach(task.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, DooStyle.Spacing.sm - 2)
                            .padding(.vertical, DooStyle.Spacing.xs)
                            .background(DooStyle.tagBg)
                            .clipShape(Capsule())
                    }
                    Button {
                        tagPopoverKey = key
                    } label: {
                        Text("+ tag")
                            .font(.caption)
                            .foregroundStyle(DooStyle.textTertiary)
                            .padding(.horizontal, DooStyle.Spacing.sm - 2)
                            .padding(.vertical, DooStyle.Spacing.xs)
                            .background(DooStyle.tagBg.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: Binding(
                        get: { tagPopoverKey == key },
                        set: { if !$0 { tagPopoverKey = nil } }
                    )) {
                        InlineTagEditor(task: task, store: store)
                    }
                }
                .frame(width: tagsWidth, alignment: .leading)
                .clipped()

                Spacer().frame(width: 7)

                // Due date
                Button {
                    dueDatePopoverKey = key
                } label: {
                    if let due = task.dueDate {
                        Text(DateFormatting.dateOnly(due))
                            .font(.caption)
                            .foregroundStyle(DateFormatting.isOverdue(due) ? DooStyle.colorRed : DooStyle.textSecondary)
                    } else {
                        Text("+ date")
                            .font(.caption)
                            .foregroundStyle(DooStyle.textTertiary)
                            .padding(.horizontal, DooStyle.Spacing.sm - 2)
                            .padding(.vertical, DooStyle.Spacing.xs)
                            .background(DooStyle.tagBg.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { dueDatePopoverKey == key },
                    set: { if !$0 { dueDatePopoverKey = nil } }
                )) {
                    InlineDueDateEditor(task: task, store: store)
                }
                .frame(width: dueWidth, alignment: .leading)

                Spacer().frame(width: 7)

                // Added date
                Text(DateFormatting.relative(task.dateAdded))
                    .font(.caption)
                    .foregroundStyle(DooStyle.textSecondary)
                    .frame(width: addedWidth, alignment: .leading)

                // Delete
                DeleteButtonCell(
                    onDelete: { withAnimation { store.deleteTask(task) } }
                )
                .frame(width: deleteWidth, alignment: .center)
            }
            .padding(.horizontal, DooStyle.Spacing.md)
            .padding(.vertical, DooStyle.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DooStyle.Radius.card)
                    .fill(isSelected ? DooStyle.accent.opacity(0.1) : isHovered ? DooStyle.tagBg.opacity(0.6) : .clear)
            )
            .contentShape(Rectangle())
            .onTapGesture { selectedTaskID = task.id }
            .onHover { hovering in hoveredRowKey = hovering ? key : nil }
            .contextMenu { taskContextMenu(task) }

            // Inline expansion
            if isExpanded,
               let index = store.activeTasks.firstIndex(where: { $0.id == task.id }) {
                InlineTaskDetail(store: store, task: $store.activeTasks[index])
                    .padding(.leading, DooStyle.Spacing.md + chevronWidth + checkWidth)
                    .padding(.trailing, DooStyle.Spacing.md + deleteWidth)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
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

    // MARK: - Helpers

    private func tasksForSection(_ section: TaskSection) -> [DooTask] {
        let filtered = section.toFilterState().apply(to: store.activeTasks)
        let asc = section.sortAscending
        return filtered.sorted { a, b in
            switch section.sortColumn {
            case "title":
                let r = a.title.localizedCompare(b.title)
                return asc ? r == .orderedAscending : r == .orderedDescending
            case "status":
                let order = PipelineStatus.allCases
                let ai = order.firstIndex(of: a.status) ?? 0
                let bi = order.firstIndex(of: b.status) ?? 0
                return asc ? ai < bi : ai > bi
            case "tags":
                let aTag = a.tags.sorted().first ?? ""
                let bTag = b.tags.sorted().first ?? ""
                if aTag.isEmpty && bTag.isEmpty { return false }
                if aTag.isEmpty { return !asc }
                if bTag.isEmpty { return asc }
                let r = aTag.localizedCompare(bTag)
                return asc ? r == .orderedAscending : r == .orderedDescending
            case "dueDate":
                let aDate = a.dueDate ?? .distantFuture
                let bDate = b.dueDate ?? .distantFuture
                return asc ? aDate < bDate : aDate > bDate
            case "dateAdded":
                return asc ? a.dateAdded < b.dateAdded : a.dateAdded > b.dateAdded
            default: // "priority"
                return asc ? a.priority < b.priority : a.priority > b.priority
            }
        }
    }

    private func toggleSort(column: String, in section: TaskSection) {
        var updated = section
        if updated.sortColumn == column {
            updated.sortAscending.toggle()
        } else {
            updated.sortColumn = column
            updated.sortAscending = true
        }
        settings.updateSection(updated)
    }

    private func submitNewTask() {
        let trimmed = newTaskInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let task = InlineSyntaxParser.parse(trimmed)
        withAnimation { store.addTask(task) }
        newTaskInput = ""
        isInputFocused = true
    }

    private func saveTitleEdit(taskID: UUID) {
        let text = editingTitleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              let index = store.activeTasks.firstIndex(where: { $0.id == taskID }) else {
            editingTitleKey = nil
            return
        }
        var updated = store.activeTasks[index]
        if updated.title != text {
            updated.title = text
            store.updateTask(updated)
        }
        editingTitleKey = nil
    }
}

// MARK: - Column resize handle

private struct ColumnResizeHandle: View {
    @Binding var rightWidth: CGFloat
    @State private var startWidth: CGFloat?

    var body: some View {
        DooStyle.separator
            .frame(width: 1, height: 14)
            .padding(.horizontal, 3)
            .frame(width: 7)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if startWidth == nil { startWidth = rightWidth }
                        guard let start = startWidth else { return }
                        rightWidth = max(40, start - value.translation.width)
                    }
                    .onEnded { _ in startWidth = nil }
            )
    }
}

// MARK: - Inline task detail

private struct InlineTaskDetail: View {
    @Bindable var store: TaskStore
    @Binding var task: DooTask

    var body: some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.sm) {
            TextEditor(text: Binding(
                get: { task.notes ?? "" },
                set: { task.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 60)
            .font(.callout)
            .scrollDisabled(true)
        }
        .padding(.vertical, DooStyle.Spacing.sm)
        .onChange(of: task) { _, newValue in
            store.updateTask(newValue)
        }
    }
}
