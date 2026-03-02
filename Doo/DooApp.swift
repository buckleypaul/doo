import SwiftUI

@main
struct DooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store: TaskStore
    @State private var settings = SettingsManager.shared

    init() {
        let s = SettingsManager.shared
        _store = State(initialValue: TaskStore(todoPath: s.todoFilePath, donePath: s.doneFilePath))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .onAppear {
                    appDelegate.configure(store: store)
                }
                .onChange(of: settings.todoFilePath) { _, _ in
                    store.updatePaths(todoPath: settings.todoFilePath, donePath: settings.doneFilePath)
                }
                .onChange(of: settings.doneFilePath) { _, _ in
                    store.updatePaths(todoPath: settings.todoFilePath, donePath: settings.doneFilePath)
                }
                .onChange(of: settings.hotkeyEnabled) { _, _ in
                    appDelegate.setupHotKey()
                }
        }

        Settings {
            SettingsView()
        }
    }
}
