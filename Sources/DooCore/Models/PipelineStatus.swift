import Foundation

public enum PipelineStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case untriaged
    case backlog
    case inProgress = "in_progress"
    case inReview = "in_review"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .untriaged: return "Untriaged"
        case .backlog: return "Backlog"
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .untriaged: return 0
        case .backlog: return 1
        case .inProgress: return 2
        case .inReview: return 3
        }
    }

    public static func fromShorthand(_ input: String) -> PipelineStatus? {
        let normalized = input.lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "untriaged": return .untriaged
        case "backlog": return .backlog
        case "inprogress": return .inProgress
        case "inreview": return .inReview
        default: return nil
        }
    }
}
