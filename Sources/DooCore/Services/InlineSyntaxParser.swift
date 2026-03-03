import Foundation

public enum InlineSyntaxParser {
    /// Parse quick-add input text into a DooTask.
    /// Syntax: `title text !N #tag @date /description`
    public static func parse(_ input: String) -> DooTask {
        var remaining = input
        var priority = 2
        var tags: [String] = []
        var dueDate: Date?
        var description: String?
        var status: PipelineStatus = .untriaged

        // Extract /description (everything after first standalone /)
        if let slashRange = remaining.range(of: " /") {
            description = String(remaining[slashRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            remaining = String(remaining[..<slashRange.lowerBound])
        }

        // Extract !N priority
        let priorityPattern = /\s*!([0-2])\s*/
        if let match = remaining.firstMatch(of: priorityPattern) {
            priority = Int(match.1)!
            remaining = remaining.replacing(priorityPattern, with: " ", maxReplacements: 1)
        }

        // Extract #tags
        let tagPattern = /\s*#(\S+)\s*/
        while let match = remaining.firstMatch(of: tagPattern) {
            tags.append(String(match.1).lowercased())
            remaining = remaining.replacing(match.0, with: " ", maxReplacements: 1)
        }

        // Extract @date
        let datePattern = /\s*@(\S+)\s*/
        if let match = remaining.firstMatch(of: datePattern) {
            let dateStr = String(match.1).lowercased()
            dueDate = parseDate(dateStr)
            remaining = remaining.replacing(match.0, with: " ", maxReplacements: 1)
        }

        // Extract %status
        let statusPattern = /\s*%(\S+)\s*/
        if let match = remaining.firstMatch(of: statusPattern) {
            if let parsed = PipelineStatus.fromShorthand(String(match.1)) {
                status = parsed
            }
            remaining = remaining.replacing(match.0, with: " ", maxReplacements: 1)
        }

        let title = remaining.trimmingCharacters(in: .whitespaces)

        return DooTask(
            title: title.isEmpty ? "Untitled" : title,
            description: description,
            priority: priority,
            tags: tags,
            dueDate: dueDate,
            status: status
        )
    }

    private static func parseDate(_ input: String) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch input {
        case "today":
            return today
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: today)
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: input)
        }
    }
}
