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
