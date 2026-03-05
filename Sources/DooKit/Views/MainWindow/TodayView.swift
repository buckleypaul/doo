import AppKit
import SwiftUI

private struct RowKey: Hashable {
    let sectionID: UUID
    let taskID: DooTask.ID
}

struct TodayView: View {
    @Bindable var store: TaskStore
    @Bindable var settings: SettingsManager
    @State private var newTaskInput = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedTaskID: DooTask.ID?
    @State private var expandedTaskIDs: Set<DooTask.ID> = []
    @State private var tagPopoverKey: RowKey?
    @State private var statusPopoverKey: RowKey?
    @State private var priorityPopoverKey: RowKey?
    @State private var dueDatePopoverKey: RowKey?
    @State private var hoveredRowKey: RowKey?
    @State private var editingTitleKey: RowKey?
    @State private var editingTitleText: String = ""
    @FocusState private var focusedTitleTaskID: DooTask.ID?

    @State private var followupsCollapsed = false
    @State private var inProgressTodayCollapsed = false

    @State private var followupsSortColumn = "priority"
    @State private var followupsSortAscending = true
    @State private var inProgressTodaySortColumn = "priority"
    @State private var inProgressTodaySortAscending = true

    @State private var statusWidth: CGFloat = 90
    @State private var priorityWidth: CGFloat = 60
    @State private var tagsWidth: CGFloat = 160
    @State private var dueWidth: CGFloat = 90
    @State private var addedWidth: CGFloat = 80

    private let checkWidth: CGFloat = 28
    private let deleteWidth: CGFloat = 40
    private let chevronWidth: CGFloat = 20

    private let followupsSectionID = UUID(uuidString: "00000000-0000-0000-0001-000000000001")!
    private let inProgressTodaySectionID = UUID(uuidString: "00000000-0000-0000-0001-000000000002")!

    private var followupTasks: [DooTask] {
        let filtered = store.activeTasks.filter { $0.tags.contains("followup") }
        return sorted(filtered, column: followupsSortColumn, ascending: followupsSortAscending)
    }

    private var inProgressTodayTasks: [DooTask] {
        let filtered = store.activeTasks.filter {
            $0.status == .inProgress && $0.dueDate.map(DateFormatting.isDueTodayOrOverdue) == true
        }
        return sorted(filtered, column: inProgressTodaySortColumn, ascending: inProgressTodaySortAscending)
    }

    var body: some View {
        VStack(spacing: 0) {
            InlineAddRow(input: $newTaskInput, isFocused: $isInputFocused) {
                submitNewTask()
            }
            Divider()
            mainContent
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

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        if followupTasks.isEmpty && inProgressTodayTasks.isEmpty {
            ContentUnavailableView(
                "Nothing for Today",
                systemImage: "sun.max",
                description: Text("Tasks tagged #followup or in-progress tasks due today will appear here.")
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    sectionView(
                        name: "Follow-ups",
                        sectionID: followupsSectionID,
                        tasks: followupTasks,
                        isCollapsed: $followupsCollapsed,
                        sortColumn: $followupsSortColumn,
                        sortAscending: $followupsSortAscending
                    )
                    sectionView(
                        name: "In Progress Today",
                        sectionID: inProgressTodaySectionID,
                        tasks: inProgressTodayTasks,
                        isCollapsed: $inProgressTodayCollapsed,
                        sortColumn: $inProgressTodaySortColumn,
                        sortAscending: $inProgressTodaySortAscending
                    )
                }
                .padding(.vertical, DooStyle.Spacing.sm)
            }
        }
    }

    // MARK: - Section

    private func sectionView(
        name: String,
        sectionID: UUID,
        tasks: [DooTask],
        isCollapsed: Binding<Bool>,
        sortColumn: Binding<String>,
        sortAscending: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: DooStyle.Spacing.sm) {
                Text(name.uppercased())
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
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DooStyle.textSecondary)
                    .rotationEffect(isCollapsed.wrappedValue ? .zero : .degrees(90))
                    .animation(.easeInOut(duration: 0.15), value: isCollapsed.wrappedValue)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isCollapsed.wrappedValue.toggle()
                }
            }
            .padding(.horizontal, DooStyle.Spacing.md)
            .padding(.vertical, DooStyle.Spacing.xs)

            Divider()
                .padding(.horizontal, DooStyle.Spacing.md)

            if !isCollapsed.wrappedValue {
                columnHeader(sectionID: sectionID, sortColumn: sortColumn, sortAscending: sortAscending)
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
                        taskRow(task, sectionID: sectionID)
                    }
                }
            }

            Spacer().frame(height: DooStyle.Spacing.md)
        }
    }

    // MARK: - Column header

    private func columnHeader(
        sectionID: UUID,
        sortColumn: Binding<String>,
        sortAscending: Binding<Bool>
    ) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: chevronWidth)
            Spacer().frame(width: checkWidth)
            sortButton("Title", column: "title", sortColumn: sortColumn, sortAscending: sortAscending)
                .frame(maxWidth: .infinity, alignment: .leading)
            ColumnResizeHandleView(rightWidth: $statusWidth)
            sortButton("Status", column: "status", sortColumn: sortColumn, sortAscending: sortAscending)
                .frame(width: statusWidth, alignment: .leading)
            ColumnResizeHandleView(rightWidth: $priorityWidth)
            sortButton("Priority", column: "priority", sortColumn: sortColumn, sortAscending: sortAscending)
                .frame(width: priorityWidth, alignment: .center)
            ColumnResizeHandleView(rightWidth: $tagsWidth)
            sortButton("Tags", column: "tags", sortColumn: sortColumn, sortAscending: sortAscending)
                .frame(width: tagsWidth, alignment: .leading)
            ColumnResizeHandleView(rightWidth: $dueWidth)
            sortButton("Due", column: "dueDate", sortColumn: sortColumn, sortAscending: sortAscending)
                .frame(width: dueWidth, alignment: .leading)
            ColumnResizeHandleView(rightWidth: $addedWidth)
            sortButton("Added", column: "dateAdded", sortColumn: sortColumn, sortAscending: sortAscending)
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

    private func sortButton(
        _ label: String,
        column: String,
        sortColumn: Binding<String>,
        sortAscending: Binding<Bool>
    ) -> some View {
        let isActive = sortColumn.wrappedValue == column
        return Button {
            if sortColumn.wrappedValue == column {
                sortAscending.wrappedValue.toggle()
            } else {
                sortColumn.wrappedValue = column
                sortAscending.wrappedValue = true
            }
        } label: {
            HStack(spacing: 2) {
                Text(label)
                if isActive {
                    Image(systemName: sortAscending.wrappedValue ? "chevron.up" : "chevron.down")
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

    // MARK: - Task row

    private func taskRow(_ task: DooTask, sectionID: UUID) -> some View {
        let key = RowKey(sectionID: sectionID, taskID: task.id)
        let isSelected = selectedTaskID == task.id
        let isHovered = hoveredRowKey == key
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

                // Title — click to edit inline
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

                Spacer().frame(width: 7)

                // Status
                Button { statusPopoverKey = key } label: {
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
                Button { priorityPopoverKey = key } label: {
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
                        todayTagPill(tag: tag, task: task, isHovered: isHovered)
                    }
                    Button { tagPopoverKey = key } label: {
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
                        InlineTagEditor(task: task, store: store, settings: settings)
                    }
                }
                .frame(width: tagsWidth, alignment: .leading)
                .clipped()

                Spacer().frame(width: 7)

                // Due date
                Button { dueDatePopoverKey = key } label: {
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
            .onTapGesture {
                selectedTaskID = task.id
                withAnimation(.easeInOut(duration: 0.15)) {
                    if expandedTaskIDs.contains(task.id) {
                        expandedTaskIDs.remove(task.id)
                    } else {
                        expandedTaskIDs.insert(task.id)
                    }
                }
            }
            .onHover { hovering in hoveredRowKey = hovering ? key : nil }
            .contextMenu { taskContextMenu(task) }

            // Inline expansion
            if isExpanded,
               let index = store.activeTasks.firstIndex(where: { $0.id == task.id }) {
                TodayInlineTaskDetail(store: store, task: $store.activeTasks[index])
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

    private func sorted(_ tasks: [DooTask], column: String, ascending asc: Bool) -> [DooTask] {
        tasks.sorted { a, b in
            switch column {
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

    private func todayTagPill(tag: String, task: DooTask, isHovered: Bool) -> some View {
        let tagColor = DooStyle.tagColor(for: tag, settings: settings)
        let bgColor = tagColor ?? DooStyle.tagBg
        let textColor = tagColor.flatMap { _ in
            if let hex = settings.tagColors[tag] {
                return DooStyle.contrastColor(for: hex)
            }
            return nil
        } ?? DooStyle.textPrimary

        return HStack(spacing: 2) {
            Text(tag).font(.caption)
            if isHovered {
                Button {
                    var updated = task
                    updated.tags.removeAll { $0 == tag }
                    store.updateTask(updated)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DooStyle.Spacing.sm - 2)
        .padding(.vertical, DooStyle.Spacing.xs)
        .background(bgColor)
        .foregroundStyle(textColor)
        .clipShape(Capsule())
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

// MARK: - Column resize handle (local copy for TodayView)

private struct ColumnResizeHandleView: View {
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

// MARK: - Inline task detail (local copy for TodayView)

private struct TodayInlineTaskDetail: View {
    @Bindable var store: TaskStore
    @Binding var task: DooTask

    private var extractedURLs: [URL] {
        guard let notes = task.notes, !notes.isEmpty else { return [] }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: notes, range: NSRange(notes.startIndex..., in: notes)) ?? []
        return matches.compactMap { $0.url }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DooStyle.Spacing.md) {
            TextEditor(text: Binding(
                get: { task.notes ?? "" },
                set: { task.notes = $0.isEmpty ? nil : $0 }
            ))
            .frame(minHeight: 60)
            .font(.callout)
            .scrollDisabled(true)

            if !extractedURLs.isEmpty {
                TodayResourcesPanel(urls: extractedURLs)
            }
        }
        .padding(.vertical, DooStyle.Spacing.sm)
        .onChange(of: task) { _, newValue in
            store.updateTask(newValue)
        }
    }
}

private struct TodayResourcesPanel: View {
    let urls: [URL]

    var body: some View {
        VStack(alignment: .leading, spacing: DooStyle.Spacing.xs) {
            Text("Resources")
                .font(.caption)
                .foregroundStyle(DooStyle.textSecondary)
            ForEach(urls, id: \.absoluteString) { url in
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Text(url.host ?? url.absoluteString)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(DooStyle.accent)
                }
                .buttonStyle(.plain)
                .help(url.absoluteString)
            }
        }
        .frame(minWidth: 120, alignment: .topLeading)
    }
}
