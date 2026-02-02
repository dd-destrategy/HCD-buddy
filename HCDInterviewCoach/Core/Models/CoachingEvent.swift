import Foundation
import SwiftData

/// Represents a coaching prompt shown during a session
@Model
final class CoachingEvent {
    @Attribute(.unique) var id: UUID
    var timestampSeconds: Double
    var promptText: String
    var reason: String
    var userResponse: CoachingResponse
    var respondedAt: Date?
    var createdAt: Date

    var session: Session?

    init(
        id: UUID = UUID(),
        timestampSeconds: Double,
        promptText: String,
        reason: String,
        userResponse: CoachingResponse = .notResponded,
        respondedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.timestampSeconds = timestampSeconds
        self.promptText = promptText
        self.reason = reason
        self.userResponse = userResponse
        self.respondedAt = respondedAt
        self.createdAt = createdAt
    }

    /// Formatted timestamp string (MM:SS)
    var formattedTimestamp: String {
        let minutes = Int(timestampSeconds) / 60
        let seconds = Int(timestampSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Whether the user has responded to this coaching event
    var hasResponse: Bool {
        userResponse != .notResponded
    }

    /// Whether the user accepted this coaching prompt
    var wasAccepted: Bool {
        userResponse == .accepted
    }

    /// Whether the user dismissed this coaching prompt
    var wasDismissed: Bool {
        userResponse == .dismissed
    }

    /// Update the user's response
    func recordResponse(_ response: CoachingResponse) {
        self.userResponse = response
        self.respondedAt = Date()
    }
}
