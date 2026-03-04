import Foundation
import DooCore

public enum TableFormatter {
    public static func formatTaskList(_ tasks: [DooTask]) -> String {
        if tasks.isEmpty {
            return "No tasks"
        }

        var lines: [String] = []

        appendHeader(&lines)

        // Rows
        for (i, task) in tasks.enumerated() {
            lines.append(formatRow(index: i + 1, task: task))
        }

        // Summary
        lines.append("")
        lines.append("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")

        return lines.joined(separator: "\n")
    }

    public static func formatGroupedTaskList(_ tasks: [DooTask]) -> String {
        if tasks.isEmpty {
            return "No tasks"
        }

        var lines: [String] = []
        var globalIndex = 1

        for status in PipelineStatus.allCases {
            let group = tasks.filter { $0.status == status }
            lines.append("")
            lines.append("── \(status.displayName) (\(group.count)) ──")

            if group.isEmpty {
                lines.append("  (none)")
            } else {
                appendHeader(&lines)
                for task in group {
                    lines.append(formatRow(index: globalIndex, task: task))
                    globalIndex += 1
                }
            }
        }

        lines.append("")
        lines.append("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")

        return lines.joined(separator: "\n")
    }

    public static func formatTaskDetail(_ task: DooTask) -> String {
        var lines: [String] = []

        lines.append("Title:       \(task.title)")
        lines.append("ID:          \(task.id.uuidString)")
        lines.append("Priority:    !\(task.priority)")
        lines.append("Status:      \(task.status.displayName)")

        if !task.tags.isEmpty {
            lines.append("Tags:        \(task.tags.map { "#\($0)" }.joined(separator: " "))")
        }

        if let dueDate = task.dueDate {
            let overdue = DateFormatting.isOverdue(dueDate) ? " (OVERDUE)" : ""
            lines.append("Due:         \(DateFormatting.dateOnly(dueDate))\(overdue)")
        }

        lines.append("Added:       \(DateFormatting.shortDateTime(task.dateAdded))")

        if let completed = task.dateCompleted {
            lines.append("Completed:   \(DateFormatting.shortDateTime(completed))")
        }

        if let notes = task.notes, !notes.isEmpty {
            lines.append("Notes:       \(notes)")
        }

        return lines.joined(separator: "\n")
    }

    private static func appendHeader(_ lines: inout [String]) {
        lines.append(
            pad("#", width: 4, right: false)
            + "  " + pad("ID", width: 8)
            + "  " + pad("P", width: 2)
            + "  " + pad("Title", width: 30)
            + "  " + pad("Due", width: 12)
            + "  " + "Tags"
        )
        lines.append(String(repeating: "-", count: 80))
    }

    private static func formatRow(index: Int, task: DooTask) -> String {
        let shortID = String(task.id.uuidString.prefix(8)).lowercased()
        let title = task.title.count > 30
            ? String(task.title.prefix(27)) + "..."
            : task.title

        let dueStr: String
        if let dueDate = task.dueDate {
            let dateStr = DateFormatting.dateOnly(dueDate)
            let overdue = DateFormatting.isOverdue(dueDate) ? " !" : ""
            dueStr = dateStr + overdue
        } else {
            dueStr = "-"
        }

        let tagsStr = task.tags.map { "#\($0)" }.joined(separator: " ")

        return pad("\(index)", width: 4, right: false)
            + "  " + pad(shortID, width: 8)
            + "  " + pad("!\(task.priority)", width: 2)
            + "  " + pad(title, width: 30)
            + "  " + pad(dueStr, width: 12)
            + "  " + tagsStr
    }

    private static func pad(_ str: String, width: Int, right: Bool = true) -> String {
        if str.count >= width { return str }
        let spaces = String(repeating: " ", count: width - str.count)
        return right ? str + spaces : spaces + str
    }
}
