import SwiftUI

struct DoneListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState(sortOption: .dateCompleted)
    @State private var taskToDelete: DooTask?

    private var filteredTasks: [DooTask] {
        filterState.apply(to: store.completedTasks)
    }

    private var allTags: [String] {
        Array(Set(store.completedTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterToolbar(filterState: $filterState, availableTags: allTags)

            Divider()

            if filteredTasks.isEmpty {
                ContentUnavailableView(
                    store.completedTasks.isEmpty ? "No Completed Tasks" : "No Matches",
                    systemImage: store.completedTasks.isEmpty ? "tray" : "magnifyingglass",
                    description: Text(store.completedTasks.isEmpty ? "Completed tasks will appear here." : "Try adjusting your filters.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        if let index = store.completedTasks.firstIndex(where: { $0.id == task.id }) {
                            DisclosureGroup {
                                TaskDetailView(store: store, task: $store.completedTasks[index])
                            } label: {
                                TaskRowView(task: task) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        store.uncompleteTask(task)
                                    }
                                }
                            }
                            .contextMenu {
                                Button("Restore to Todo") {
                                    withAnimation { store.uncompleteTask(task) }
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
}
