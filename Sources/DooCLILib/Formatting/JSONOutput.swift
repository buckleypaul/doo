import Foundation
import DooCore

public enum JSONOutput {
    public static func encode(_ tasks: [DooTask]) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(tasks)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    public static func encode(_ task: DooTask) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(task)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
