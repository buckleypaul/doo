import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case todo = "Todo"
    case done = "Done"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todo: "checklist"
        case .done: "checkmark.circle"
        }
    }
}

struct ContentView: View {
    @State var store: TaskStore
    @State private var selection: SidebarItem? = .todo

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selection {
            case .todo:
                TodoListView(store: store)
                    .navigationTitle("Todo")
            case .done:
                DoneListView(store: store)
                    .navigationTitle("Done")
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
