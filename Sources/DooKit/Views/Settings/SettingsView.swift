import SwiftUI

struct SettingsView: View {
    @State private var settings = SettingsManager.shared

    var body: some View {
        Form {
            Section("File Paths") {
                HStack {
                    TextField("Todo file", text: $settings.todoFilePath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        browseForFile(current: settings.todoFilePath) { path in
                            settings.todoFilePath = path
                        }
                    }
                }

                HStack {
                    TextField("Done file", text: $settings.doneFilePath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        browseForFile(current: settings.doneFilePath) { path in
                            settings.doneFilePath = path
                        }
                    }
                }
            }

            Section("Hotkey") {
                Toggle("Enable global hotkey (Option+Space)", isOn: $settings.hotkeyEnabled)
            }

            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle("Group tasks by pipeline status", isOn: $settings.groupByStatus)
            }
        }
        .formStyle(.grouped)
    }

    private func browseForFile(current: String, completion: @escaping (String) -> Void) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = URL(fileURLWithPath: current).lastPathComponent
        panel.directoryURL = URL(fileURLWithPath: current).deletingLastPathComponent()
        panel.allowedContentTypes = [.json]

        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }
}
