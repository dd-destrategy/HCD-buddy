import Foundation

/// Defines the operational mode for an interview session
enum SessionMode: String, CaseIterable, Codable {
    case full = "Full"
    case transcriptionOnly = "Transcription Only"
    case observerOnly = "Observer Only"

    var displayName: String {
        switch self {
        case .full:
            return "Full"
        case .transcriptionOnly:
            return "Transcription Only"
        case .observerOnly:
            return "Observer Only"
        }
    }

    var description: String {
        switch self {
        case .full:
            return "Transcription + Coaching + Insights"
        case .transcriptionOnly:
            return "No AI coaching, just transcript"
        case .observerOnly:
            return "No recording, topic tracking only"
        }
    }

    var isRecordingEnabled: Bool {
        self != .observerOnly
    }

    var isCoachingEnabled: Bool {
        self == .full
    }

    var isInsightsEnabled: Bool {
        self == .full
    }
}
