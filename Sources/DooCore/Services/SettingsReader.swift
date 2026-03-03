import Foundation

public struct SettingsConfig: Codable, Sendable {
    public var todoFilePath: String
    public var doneFilePath: String
    public var hotkeyEnabled: Bool
    public var launchAtLogin: Bool
    public var groupByStatus: Bool

    public init(
        todoFilePath: String,
        doneFilePath: String,
        hotkeyEnabled: Bool = true,
        launchAtLogin: Bool = false,
        groupByStatus: Bool = true
    ) {
        self.todoFilePath = todoFilePath
        self.doneFilePath = doneFilePath
        self.hotkeyEnabled = hotkeyEnabled
        self.launchAtLogin = launchAtLogin
        self.groupByStatus = groupByStatus
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todoFilePath = try container.decode(String.self, forKey: .todoFilePath)
        doneFilePath = try container.decode(String.self, forKey: .doneFilePath)
        hotkeyEnabled = try container.decodeIfPresent(Bool.self, forKey: .hotkeyEnabled) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        groupByStatus = try container.decodeIfPresent(Bool.self, forKey: .groupByStatus) ?? true
    }
}

public enum SettingsReader {
    public static let defaultConfigURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/doo/settings.json")
    }()

    public static var defaultTodoPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/doo/todo.json").path
    }

    public static var defaultDonePath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/doo/done.json").path
    }

    public static func load(from url: URL? = nil) -> SettingsConfig {
        let configURL = url ?? defaultConfigURL
        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(SettingsConfig.self, from: data) {
            return config
        }
        return SettingsConfig(
            todoFilePath: defaultTodoPath,
            doneFilePath: defaultDonePath
        )
    }
}
