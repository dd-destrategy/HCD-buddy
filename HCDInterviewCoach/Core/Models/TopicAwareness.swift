import Foundation

/// Represents the status of topic coverage in a session
enum TopicAwareness: String, Codable, CaseIterable {
    case notCovered = "not_covered"
    case partialCoverage = "partial_coverage"
    case fullyCovered = "fully_covered"
    case skipped = "skipped"

    var displayName: String {
        switch self {
        case .notCovered:
            return "Not Covered"
        case .partialCoverage:
            return "Partial Coverage"
        case .fullyCovered:
            return "Fully Covered"
        case .skipped:
            return "Skipped"
        }
    }

    var icon: String {
        switch self {
        case .notCovered:
            return "circle"
        case .partialCoverage:
            return "circle.lefthalf.filled"
        case .fullyCovered:
            return "checkmark.circle.fill"
        case .skipped:
            return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .notCovered:
            return "gray"
        case .partialCoverage:
            return "orange"
        case .fullyCovered:
            return "green"
        case .skipped:
            return "red"
        }
    }
}
