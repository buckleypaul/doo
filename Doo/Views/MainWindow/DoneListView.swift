import SwiftUI

struct DoneListView: View {
    @Bindable var store: TaskStore

    var body: some View {
        Group {
            if store.completedTasks.isEmpty {
                ContentUnavailableView(
                    "No Completed Tasks",
                    systemImage: "tray",
                    description: Text("Completed tasks will appear here.")
                )
            } else {
                List(store.completedTasks) { task in
                    TaskRowView(task: task) {
                        store.uncompleteTask(task)
                    }
                }
            }
        }
    }
}
