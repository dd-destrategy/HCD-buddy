import Foundation

/// Represents how an insight was generated
enum InsightSource: String, Codable, CaseIterable {
    case aiGenerated = "ai_generated"
    case userAdded = "user_added"
    case automated = "automated"

    var displayName: String {
        switch self {
        case .aiGenerated:
            return "AI Generated"
        case .userAdded:
            return "User Added"
        case .automated:
            return "Automated"
        }
    }

    var icon: String {
        switch self {
        case .aiGenerated:
            return "sparkles"
        case .userAdded:
            return "person.crop.circle.badge.plus"
        case .automated:
            return "gearshape.fill"
        }
    }
}
