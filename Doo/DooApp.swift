import SwiftUI

@main
struct DooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var store = TaskStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
