import Foundation
import SwiftData

/// Represents an insight extracted from the session
@Model
final class Insight {
    @Attribute(.unique) var id: UUID
    var timestampSeconds: Double
    var quote: String
    var theme: String
    var source: InsightSource
    var createdAt: Date
    var tags: [String]

    var session: Session?

    init(
        id: UUID = UUID(),
        timestampSeconds: Double,
        quote: String,
        theme: String,
        source: InsightSource,
        createdAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.timestampSeconds = timestampSeconds
        self.quote = quote
        self.theme = theme
        self.source = source
        self.createdAt = createdAt
        self.tags = tags
    }

    /// Formatted timestamp string (MM:SS)
    var formattedTimestamp: String {
        let minutes = Int(timestampSeconds) / 60
        let seconds = Int(timestampSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Whether this insight was AI-generated
    var isAIGenerated: Bool {
        source == .aiGenerated
    }

    /// Whether this insight was manually added by the user
    var isUserAdded: Bool {
        source == .userAdded
    }
}
