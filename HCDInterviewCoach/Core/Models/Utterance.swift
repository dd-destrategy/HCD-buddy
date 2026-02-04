import Foundation
import SwiftData

/// Represents a single utterance (speech segment) in a session
@Model
final class Utterance {
    @Attribute(.unique) var id: UUID
    var speaker: Speaker
    var text: String
    var timestampSeconds: Double
    var confidence: Double?
    var createdAt: Date

    var session: Session?

    init(
        id: UUID = UUID(),
        speaker: Speaker,
        text: String,
        timestampSeconds: Double,
        confidence: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.speaker = speaker
        self.text = text
        self.timestampSeconds = timestampSeconds
        self.confidence = confidence
        self.createdAt = createdAt
    }

    /// Formatted timestamp string (MM:SS)
    var formattedTimestamp: String {
        let minutes = Int(timestampSeconds) / 60
        let seconds = Int(timestampSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Whether this utterance has high confidence
    var hasHighConfidence: Bool {
        guard let confidence = confidence else { return true }
        return confidence >= 0.8
    }

    /// Word count in the utterance
    var wordCount: Int {
        text.split(separator: " ").count
    }
}
