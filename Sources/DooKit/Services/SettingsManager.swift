import Foundation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
public class SettingsManager {
    public static let shared = SettingsManager()

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
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let url = configDir.appendingPathComponent("settings.json")
        self.init(configURL: url)
    }

    // Package-internal init for testing — accepts any config file URL.
    init(configURL: URL) {
        self.configURL = configURL
        let config = SettingsReader.load(from: configURL)
        self.todoFilePath = config.todoFilePath
        self.doneFilePath = config.doneFilePath
        self.hotkeyEnabled = config.hotkeyEnabled
        self.launchAtLogin = config.launchAtLogin
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
            try data.write(to: tmp)
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
