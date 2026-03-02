import Foundation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
public class SettingsManager {
    public static let shared = SettingsManager()

    public var todoFilePath: String {
        didSet { UserDefaults.standard.set(todoFilePath, forKey: "todoFilePath") }
    }

    public var doneFilePath: String {
        didSet { UserDefaults.standard.set(doneFilePath, forKey: "doneFilePath") }
    }

    public var hotkeyEnabled: Bool {
        didSet { UserDefaults.standard.set(hotkeyEnabled, forKey: "hotkeyEnabled") }
    }

    public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.todoFilePath = UserDefaults.standard.string(forKey: "todoFilePath")
            ?? "\(home)/doo-todo.json"
        self.doneFilePath = UserDefaults.standard.string(forKey: "doneFilePath")
            ?? "\(home)/doo-done.json"
        self.hotkeyEnabled = UserDefaults.standard.object(forKey: "hotkeyEnabled") as? Bool ?? true
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
