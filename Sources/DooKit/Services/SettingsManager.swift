import Foundation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
public class SettingsManager {
    public static let shared = SettingsManager()

    // MARK: - Codable config

    struct SettingsConfig: Codable {
        var todoFilePath: String
        var doneFilePath: String
        var hotkeyEnabled: Bool
        var launchAtLogin: Bool
    }

    // MARK: - Public properties

    public var todoFilePath: String {
        didSet { saveConfig() }
    }

    public var doneFilePath: String {
        didSet { saveConfig() }
    }

    public var hotkeyEnabled: Bool {
        didSet { saveConfig() }
    }

    public var launchAtLogin: Bool {
        didSet {
            saveConfig()
            updateLaunchAtLogin()
        }
    }

    // MARK: - Private

    private let configURL: URL

    // MARK: - Init

    public convenience init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/doo")
        let url = configDir.appendingPathComponent("settings.json")
        self.init(configURL: url)
    }

    // Package-internal init for testing — accepts any config file URL.
    init(configURL: URL) {
        self.configURL = configURL
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let defaultTodo = "\(home)/.local/share/doo/todo.json"
        let defaultDone = "\(home)/.local/share/doo/done.json"

        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(SettingsConfig.self, from: data) {
            self.todoFilePath = config.todoFilePath
            self.doneFilePath = config.doneFilePath
            self.hotkeyEnabled = config.hotkeyEnabled
            self.launchAtLogin = config.launchAtLogin
        } else {
            self.todoFilePath = defaultTodo
            self.doneFilePath = defaultDone
            self.hotkeyEnabled = true
            self.launchAtLogin = false
        }
    }

    // MARK: - Persistence

    private func saveConfig() {
        let config = SettingsConfig(
            todoFilePath: todoFilePath,
            doneFilePath: doneFilePath,
            hotkeyEnabled: hotkeyEnabled,
            launchAtLogin: launchAtLogin
        )
        do {
            let dir = configURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(config)
            let tmp = dir.appendingPathComponent(".settings.tmp")
            try data.write(to: tmp, options: .atomic)
            _ = try FileManager.default.replaceItemAt(configURL, withItemAt: tmp)
        } catch {
            print("SettingsManager: failed to save config: \(error)")
        }
    }

    // MARK: - Launch at login

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
