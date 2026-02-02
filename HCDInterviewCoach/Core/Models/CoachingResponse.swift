import Foundation

/// Represents how the user responded to a coaching prompt
enum CoachingResponse: String, Codable, CaseIterable {
    case accepted = "accepted"
    case dismissed = "dismissed"
    case snoozed = "snoozed"
    case notResponded = "not_responded"

    var displayName: String {
        switch self {
        case .accepted:
            return "Accepted"
        case .dismissed:
            return "Dismissed"
        case .snoozed:
            return "Snoozed"
        case .notResponded:
            return "Not Responded"
        }
    }

    var icon: String {
        switch self {
        case .accepted:
            return "checkmark.circle.fill"
        case .dismissed:
            return "xmark.circle.fill"
        case .snoozed:
            return "clock.fill"
        case .notResponded:
            return "circle"
        }
    }
}
