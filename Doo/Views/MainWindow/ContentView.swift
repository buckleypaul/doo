import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case todo = "Todo"
    case done = "Done"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .todo: "checklist"
        case .done: "checkmark.circle"
        case .settings: "gear"
        }
    }
}

extension Notification.Name {
    static let showSettingsPage = Notification.Name("DooShowSettingsPage")
}

struct ContentView: View {
    @State var store: TaskStore
    @State private var selection: SidebarItem? = .todo

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label {
                    Text(item.rawValue)
                } icon: {
                    Image(systemName: item.icon)
                }
                .badge(badgeCount(for: item))
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
            case .settings:
                SettingsView()
                    .navigationTitle("Settings")
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .showSettingsPage)) { _ in
            selection = .settings
        }
    }

    private func badgeCount(for item: SidebarItem) -> Int {
        switch item {
        case .todo: store.activeTasks.count
        case .done: store.completedTasks.count
        case .settings: 0
        }
    }
}
