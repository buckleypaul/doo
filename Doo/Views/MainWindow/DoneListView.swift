import SwiftUI

struct DoneListView: View {
    @Bindable var store: TaskStore
    @State private var filterState = FilterState(sortOption: .dateCompleted)

    private var filteredTasks: [DooTask] {
        filterState.apply(to: store.completedTasks)
    }

    private var allTags: [String] {
        Array(Set(store.completedTasks.flatMap(\.tags))).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterToolbar(filterState: $filterState, availableTags: allTags, showDateCompleted: true)

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
                                    withAnimation {
                                        store.uncompleteTask(task)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
