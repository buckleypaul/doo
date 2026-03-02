import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState()
    @State private var taskToDelete: DooTask?

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let newTask = DooTask(title: "New Task")
                    withAnimation {
                        store.addTask(newTask)
                    }
                } label: {
                    Label("Add Task", systemImage: "plus")
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
