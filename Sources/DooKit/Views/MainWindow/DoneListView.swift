import AppKit
import SwiftUI

struct DoneListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState(sortOption: .dateCompleted)
    @State private var selectedTaskID: DooTask.ID?
    @State private var sortOrder = [KeyPathComparator(\DooTask.dateCompletedSortKey, order: .reverse)]
    @State private var showDetail = true
    @State private var savedDetailWidth: CGFloat = 320
    @State private var dragStartWidth: CGFloat? = nil

    private var displayedTasks: [DooTask] {
        filterState.apply(to: store.completedTasks).sorted(using: sortOrder)
    }

    private var allTags: [String] {
        Array(Set(store.completedTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                FilterToolbar(filterState: $filterState, availableTags: allTags)
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
        .onChange(of: store.completedTasks) { _, tasks in
            if let id = selectedTaskID, !tasks.contains(where: { $0.id == id }) {
                selectedTaskID = nil
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        VStack(spacing: 0) {
            if let id = selectedTaskID,
               let index = store.completedTasks.firstIndex(where: { $0.id == id }) {
                TaskDetailView(store: store, task: $store.completedTasks[index])
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
                store.completedTasks.isEmpty ? "No Completed Tasks" : "No Matches",
                systemImage: store.completedTasks.isEmpty ? "tray" : "magnifyingglass",
                description: Text(store.completedTasks.isEmpty ? "Completed tasks will appear here." : "Try adjusting your filters.")
            )
            .frame(maxHeight: .infinity)
        } else {
            Table(displayedTasks, selection: Binding(
                get: { selectedTaskID },
                set: { if let id = $0 { selectedTaskID = id } }
            ), sortOrder: $sortOrder) {
                TableColumn("") { task in
                    CompleteButtonCell(isCompleted: true) {
                        store.uncompleteTask(task)
                    }
                    .tableCell(alignment: .center)
                }
                .width(DooStyle.Size.icon + DooStyle.Spacing.sm)
                TableColumn("Title", value: \.title) { task in
                    Text(task.title)
                        .foregroundStyle(.secondary)
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
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .tableCell()
                }
                .width(100)
                TableColumn("Completed", value: \.dateCompletedSortKey) { task in
                    Group {
                        if let completed = task.dateCompleted {
                            Text(DateFormatting.relative(completed))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tableCell()
                }
                .width(110)
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
                   let task = store.completedTasks.first(where: { $0.id == id }) {
                    Button("Restore to Todo") {
                        withAnimation { store.uncompleteTask(task) }
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        withAnimation { store.deleteTask(task) }
                    }
                }
            }
        }
    }
}
