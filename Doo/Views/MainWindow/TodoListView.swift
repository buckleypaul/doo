import SwiftUI

struct TodoListView: View {
    @Bindable var store: TaskStore

    var body: some View {
        Group {
            if store.activeTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Add a task to get started.")
                )
            } else {
                List(store.activeTasks) { task in
                    TaskRowView(task: task) {
                        store.completeTask(task)
                    }
                }
            }
        }
    }
}
