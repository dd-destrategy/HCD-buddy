import Foundation
import SwiftData

/// Represents the coverage status of a topic in a session
@Model
final class TopicStatus {
    @Attribute(.unique) var id: UUID
    var topicId: String
    var topicName: String
    var status: TopicAwareness
    var lastUpdated: Date
    var notes: String?

    var session: Session?

    init(
        id: UUID = UUID(),
        topicId: String,
        topicName: String,
        status: TopicAwareness = .notCovered,
        lastUpdated: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.topicId = topicId
        self.topicName = topicName
        self.status = status
        self.lastUpdated = lastUpdated
        self.notes = notes
    }

    /// Whether this topic has been covered at all
    var isCovered: Bool {
        status == .partialCoverage || status == .fullyCovered
    }

    /// Whether this topic is fully covered
    var isFullyCovered: Bool {
        status == .fullyCovered
    }

    /// Whether this topic was skipped
    var isSkipped: Bool {
        status == .skipped
    }

    /// Update the status and timestamp
    func updateStatus(_ newStatus: TopicAwareness) {
        self.status = newStatus
        self.lastUpdated = Date()
    }
}
