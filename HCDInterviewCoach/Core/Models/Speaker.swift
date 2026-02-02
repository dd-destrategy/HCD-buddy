import Foundation

/// Represents who is speaking in an utterance
enum Speaker: String, Codable, CaseIterable {
    case interviewer = "interviewer"
    case participant = "participant"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .interviewer:
            return "Interviewer"
        case .participant:
            return "Participant"
        case .unknown:
            return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .interviewer:
            return "person.fill"
        case .participant:
            return "person.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}
