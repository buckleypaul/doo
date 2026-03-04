import Foundation

public struct DooTask: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var notes: String?
    public var priority: Int
    public var tags: [String]
    public var dueDate: Date?
    public var dateAdded: Date
    public var dateCompleted: Date?
    public var status: PipelineStatus
    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        priority: Int = 2,
        tags: [String] = [],
        dueDate: Date? = nil,
        dateAdded: Date = Date(),
        dateCompleted: Date? = nil,
        status: PipelineStatus = .triage
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.priority = priority
        self.tags = tags
        self.dueDate = dueDate
        self.dateAdded = dateAdded
        self.dateCompleted = dateCompleted
        self.status = status
    }
}

public struct TaskFile: Codable, Sendable {
    public var tasks: [DooTask]

    public init(tasks: [DooTask]) {
        self.tasks = tasks
    }
}

extension DooTask {
    /// Custom date coding: dueDate uses yyyy-MM-dd, dateAdded/dateCompleted use ISO8601 with seconds
    enum CodingKeys: String, CodingKey {
        case id, title, notes, priority, tags
        case dueDate, dateAdded, dateCompleted, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let rawPriority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 2
        priority = min(max(0, rawPriority), 2)   // migrate old values (3-5 → 2)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        dateCompleted = try container.decodeIfPresent(Date.self, forKey: .dateCompleted)
        // Decode status with backward compat for legacy "untriaged" raw value
        let rawStatus = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "triage"
        status = (rawStatus == "untriaged" ? .triage : PipelineStatus(rawValue: rawStatus)) ?? .triage

        // dueDate is date-only string "yyyy-MM-dd"
        if let dueDateString = try container.decodeIfPresent(String.self, forKey: .dueDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            dueDate = formatter.date(from: dueDateString)
        } else {
            dueDate = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(priority, forKey: .priority)
        try container.encode(tags, forKey: .tags)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encodeIfPresent(dateCompleted, forKey: .dateCompleted)
        try container.encode(status, forKey: .status)

        // dueDate as date-only string
        if let dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            try container.encode(formatter.string(from: dueDate), forKey: .dueDate)
        } else {
            try container.encodeIfPresent(String?.none, forKey: .dueDate)
        }
    }
}

extension DooTask {
    /// Sort key for dueDate — nil tasks sort after dated tasks
    public var dueDateSortKey: Date { dueDate ?? .distantFuture }

    /// Sort key for dateCompleted — uses .distantPast for nil so uncompleted tasks
    /// sort first in ascending order. For most-recently-completed first, sort descending.
    public var dateCompletedSortKey: Date { dateCompleted ?? .distantPast }
}
