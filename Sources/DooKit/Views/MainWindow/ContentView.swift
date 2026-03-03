import SwiftUI

public enum SidebarItem: String, CaseIterable, Identifiable {
    case todo = "Todo"
    case done = "Done"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .todo: "checklist"
        case .done: "checkmark.circle"
        case .settings: "gear"
        }
    }
}

extension Notification.Name {
    public static let showSettingsPage = Notification.Name("DooShowSettingsPage")
}

public struct ContentView: View {
    @State var store: TaskStore
    @State var settings = SettingsManager.shared
    @State private var selection: SidebarItem? = .todo

    public init(store: TaskStore) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label {
                    Text(item.rawValue)
                } icon: {
                    Image(systemName: item.icon)
                }
                .badge(badgeCount(for: item))
                .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selection {
            case .todo:
                TodoListView(store: store, settings: settings)
                    .navigationTitle("Todo")
            case .done:
                DoneListView(store: store)
                    .navigationTitle("Done")
            case .settings:
                SettingsView()
                    .navigationTitle("Settings")
            case nil:
                Text("Select a section")
                    .foregroundStyle(DooStyle.textSecondary)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(DooStyle.background)
        .tint(DooStyle.accent)
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
