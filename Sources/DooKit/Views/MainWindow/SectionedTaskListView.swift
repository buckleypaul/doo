import AppKit
import SwiftUI

struct SectionedTaskListView: View {
    @Bindable var store: TaskStore
    @Bindable var settings: SettingsManager
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedTaskID: DooTask.ID?
    @State private var showDetail = true
    @State private var savedDetailWidth: CGFloat = 320
    @State private var dragStartWidth: CGFloat? = nil
    @State private var editorSectionID: UUID?
    @State private var tagPopoverTaskID: DooTask.ID?
    @State private var statusPopoverTaskID: DooTask.ID?
    @State private var dueDatePopoverTaskID: DooTask.ID?
    @State private var hoveredTaskID: DooTask.ID?
    @State private var editingTitleTaskID: DooTask.ID?
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

    private var sortedSections: [TaskSection] {
        settings.sections.sorted { $0.order < $1.order }
    }

    private var allTags: [String] {
        Array(Set(store.activeTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                InlineAddRow(input: $newTaskInput, isFocused: $isInputFocused) {
                    submitNewTask()
                }
                Divider()
                columnHeader
                Divider()
                sectionContent
            }
            .frame(minWidth: 300, maxWidth: .infinity)
            .onChange(of: focusedTitleTaskID) { oldValue, newValue in
                if let taskID = oldValue, newValue == nil {
                    saveTitleEdit(taskID: taskID)
                }
            }

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

    // MARK: - Column header

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: checkWidth)
            Text("Title")
                .frame(maxWidth: .infinity, alignment: .leading)
            columnDivider(width: $statusWidth)
            Text("Status").frame(width: statusWidth, alignment: .leading)
            columnDivider(width: $priorityWidth)
            Text("Priority").frame(width: priorityWidth, alignment: .center)
            columnDivider(width: $tagsWidth)
            Text("Tags").frame(width: tagsWidth, alignment: .leading)
            columnDivider(width: $dueWidth)
            Text("Due").frame(width: dueWidth, alignment: .leading)
            columnDivider(width: $addedWidth)
            Text("Added").frame(width: addedWidth, alignment: .leading)
            Spacer().frame(width: deleteWidth)
        }
        .fixedSize(horizontal: false, vertical: true)
        .font(.caption)
        .foregroundStyle(DooStyle.textSecondary)
        .padding(.horizontal, DooStyle.Spacing.md)
        .padding(.vertical, DooStyle.Spacing.xs)
        .background(DooStyle.surface)
    }

    private func columnDivider(width: Binding<CGFloat>) -> some View {
        ColumnResizeHandle(width: width)
    }

    // MARK: - Detail panel

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
                if tasks.isEmpty {
                    Text("No matching tasks")
                        .font(.caption)
                        .foregroundStyle(DooStyle.textTertiary)
                        .padding(.horizontal, DooStyle.Spacing.md)
                        .padding(.vertical, DooStyle.Spacing.sm)
                } else {
                    ForEach(tasks) { task in
                        taskRow(task)
                    }
                }
            }

            Spacer().frame(height: DooStyle.Spacing.md)
        }
    }

    // MARK: - Task row (tabular)

    private func taskRow(_ task: DooTask) -> some View {
        let isSelected = selectedTaskID == task.id
        let isHovered = hoveredTaskID == task.id
        return HStack(spacing: 0) {
            // Check
            CompleteButtonCell(isCompleted: false) {
                store.completeTask(task)
            }
            .frame(width: checkWidth, alignment: .center)

            // Title (flexible) — click to edit inline
            if editingTitleTaskID == task.id {
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
                        if let prev = editingTitleTaskID, prev != task.id {
                            saveTitleEdit(taskID: prev)
                        }
                        selectedTaskID = task.id
                        editingTitleTaskID = task.id
                        editingTitleText = task.title
                        focusedTitleTaskID = task.id
                    }
            }

            // Status
            Button {
                statusPopoverTaskID = task.id
            } label: {
                Text(task.status.displayName)
                    .font(.caption)
                    .foregroundStyle(DooStyle.textSecondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: Binding(
                get: { statusPopoverTaskID == task.id },
                set: { if !$0 { statusPopoverTaskID = nil } }
            )) {
                InlineStatusEditor(task: task, store: store)
            }
            .frame(width: statusWidth, alignment: .leading)

            // Priority
            PriorityBadge(priority: task.priority)
                .frame(width: priorityWidth, alignment: .center)

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
                    tagPopoverTaskID = task.id
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
                    get: { tagPopoverTaskID == task.id },
                    set: { if !$0 { tagPopoverTaskID = nil } }
                )) {
                    InlineTagEditor(task: task, store: store)
                }
            }
            .frame(width: tagsWidth, alignment: .leading)
            .clipped()

            // Due date
            Button {
                dueDatePopoverTaskID = task.id
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
                get: { dueDatePopoverTaskID == task.id },
                set: { if !$0 { dueDatePopoverTaskID = nil } }
            )) {
                InlineDueDateEditor(task: task, store: store)
            }
            .frame(width: dueWidth, alignment: .leading)

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
        .onHover { hovering in hoveredTaskID = hovering ? task.id : nil }
        .contextMenu { taskContextMenu(task) }
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
        section.toFilterState().apply(to: store.activeTasks)
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
            editingTitleTaskID = nil
            return
        }
        var updated = store.activeTasks[index]
        if updated.title != text {
            updated.title = text
            store.updateTask(updated)
        }
        editingTitleTaskID = nil
    }
}

// MARK: - Column resize handle

private struct ColumnResizeHandle: View {
    @Binding var width: CGFloat
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
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if startWidth == nil { startWidth = width }
                        width = max(40, (startWidth ?? width) + value.translation.width)
                    }
                    .onEnded { _ in startWidth = nil }
            )
    }
}
