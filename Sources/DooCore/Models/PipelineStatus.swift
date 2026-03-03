import Foundation

public enum PipelineStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case triage
    case backlog
    case inProgress = "in_progress"
    case inReview = "in_review"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .triage: return "Triage"
        case .backlog: return "Backlog"
        case .inProgress: return "In Progress"
        case .inReview: return "In Review"
        }
    }

    public static func fromShorthand(_ input: String) -> PipelineStatus? {
        let normalized = input.lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "triage":    return .triage
        case "untriaged": return .triage   // backward compat
        case "backlog": return .backlog
        case "inprogress": return .inProgress
        case "inreview": return .inReview
        default: return nil
        }
    }
}
