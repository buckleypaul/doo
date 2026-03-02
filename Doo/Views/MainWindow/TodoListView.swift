import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState()

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
                                    withAnimation {
                                        store.completeTask(task)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let newTask = DooTask(title: "New Task")
                    store.addTask(newTask)
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
    }
}
