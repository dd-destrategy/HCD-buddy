import Foundation
import SwiftData

/// Represents an interview session
@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var participantName: String
    var projectName: String
    var sessionMode: SessionMode
    @Attribute(.indexed) var startedAt: Date
    @Attribute(.indexed) var endedAt: Date?
    var audioFilePath: String?
    var totalDurationSeconds: Double
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \Utterance.session)
    var utterances: [Utterance]

    @Relationship(deleteRule: .cascade, inverse: \Insight.session)
    var insights: [Insight]

    @Relationship(deleteRule: .cascade, inverse: \TopicStatus.session)
    var topicStatuses: [TopicStatus]

    @Relationship(deleteRule: .cascade, inverse: \CoachingEvent.session)
    var coachingEvents: [CoachingEvent]

    init(
        id: UUID = UUID(),
        participantName: String,
        projectName: String,
        sessionMode: SessionMode,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        audioFilePath: String? = nil,
        totalDurationSeconds: Double = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.participantName = participantName
        self.projectName = projectName
        self.sessionMode = sessionMode
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.audioFilePath = audioFilePath
        self.totalDurationSeconds = totalDurationSeconds
        self.notes = notes
        self.utterances = []
        self.insights = []
        self.topicStatuses = []
        self.coachingEvents = []
    }

    /// Whether the session is currently in progress
    var isInProgress: Bool {
        endedAt == nil
    }

    /// Computed duration in seconds
    var durationSeconds: Double {
        if let endedAt = endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    /// Number of utterances in this session
    var utteranceCount: Int {
        utterances.count
    }

    /// Number of insights in this session
    var insightCount: Int {
        insights.count
    }
}
