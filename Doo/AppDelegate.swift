import AppKit
import HotKey
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var quickAddPanel: QuickAddPanel?
    private var hotKey: HotKey?
    private var store: TaskStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupMenuBar()
    }

    func configure(store: TaskStore) {
        self.store = store
        self.quickAddPanel = QuickAddPanel(store: store)
        setupHotKey()
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Doo")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quick Add Task", action: #selector(quickAddAction), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Open Doo", action: #selector(openMainWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Doo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func quickAddAction() {
        quickAddPanel?.toggle()
    }

    @objc private func openMainWindow() {
        NSApp.activate()
        NSApp.windows.first(where: { !($0 is NSPanel) })?.makeKeyAndOrderFront(nil)
    }

    @objc private func openSettings() {
        openMainWindow()
        NotificationCenter.default.post(name: .showSettingsPage, object: nil)
    }

    // MARK: - Global Hotkey

    func setupHotKey() {
        let settings = SettingsManager.shared
        if settings.hotkeyEnabled {
            hotKey = HotKey(key: .space, modifiers: [.option])
            hotKey?.keyDownHandler = { [weak self] in
                self?.quickAddPanel?.toggle()
            }
        } else {
            hotKey = nil
        }
    }

    func toggleQuickAdd() {
        quickAddPanel?.toggle()
    }
}
