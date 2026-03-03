import Foundation

public enum DueDateParser {
    public static func parse(_ input: String) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch input.lowercased() {
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
