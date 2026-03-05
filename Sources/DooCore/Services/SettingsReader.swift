import Foundation

public struct SettingsConfig: Codable, Sendable {
    public var todoFilePath: String
    public var doneFilePath: String
    public var hotkeyEnabled: Bool
    public var launchAtLogin: Bool
    public var sections: [TaskSection]
    public var tagColors: [String: String]
    public var availableTagColors: [TagColor]

    public init(
        todoFilePath: String,
        doneFilePath: String,
        hotkeyEnabled: Bool = true,
        launchAtLogin: Bool = false,
        sections: [TaskSection] = [.defaultSection],
        tagColors: [String: String] = [:],
        availableTagColors: [TagColor] = TagColor.defaultPalette()
    ) {
        self.todoFilePath = todoFilePath
        self.doneFilePath = doneFilePath
        self.hotkeyEnabled = hotkeyEnabled
        self.launchAtLogin = launchAtLogin
        self.sections = sections
        self.tagColors = tagColors
        self.availableTagColors = availableTagColors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todoFilePath = try container.decode(String.self, forKey: .todoFilePath)
        doneFilePath = try container.decode(String.self, forKey: .doneFilePath)
        hotkeyEnabled = try container.decodeIfPresent(Bool.self, forKey: .hotkeyEnabled) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        sections = try container.decodeIfPresent([TaskSection].self, forKey: .sections) ?? [.defaultSection]
        tagColors = try container.decodeIfPresent([String: String].self, forKey: .tagColors) ?? [:]
        availableTagColors = try container.decodeIfPresent([TagColor].self, forKey: .availableTagColors) ?? TagColor.defaultPalette()
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
