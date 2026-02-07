//
//  Highlight.swift
//  HCDInterviewCoach
//
//  FEATURE E: Highlight Reel & Quote Library
//  A saved transcript highlight/quote with category, notes, and star support.
//  Uses lightweight struct approach (not SwiftData @Model) to avoid schema migration complexity.
//

import Foundation

// MARK: - HighlightCategory

/// Category for organizing highlights into research themes.
///
/// Each category has a display name, SF Symbol icon, and a hex color
/// for visual distinction in the Quote Library and Highlight Creator views.
enum HighlightCategory: String, CaseIterable, Codable {
    case painPoint = "pain_point"
    case userNeed = "user_need"
    case delight = "delight"
    case workaround = "workaround"
    case featureRequest = "feature_request"
    case keyQuote = "key_quote"
    case uncategorized = "uncategorized"

    /// Human-readable display name for the category
    var displayName: String {
        switch self {
        case .painPoint: return "Pain Point"
        case .userNeed: return "User Need"
        case .delight: return "Delight"
        case .workaround: return "Workaround"
        case .featureRequest: return "Feature Request"
        case .keyQuote: return "Key Quote"
        case .uncategorized: return "Uncategorized"
        }
    }

    /// SF Symbol icon name for the category
    var icon: String {
        switch self {
        case .painPoint: return "exclamationmark.triangle.fill"
        case .userNeed: return "person.fill.questionmark"
        case .delight: return "face.smiling.fill"
        case .workaround: return "arrow.triangle.turn.up.right.diamond.fill"
        case .featureRequest: return "lightbulb.fill"
        case .keyQuote: return "quote.opening"
        case .uncategorized: return "tag.fill"
        }
    }

    /// Hex color string for the category, used for UI indicators
    var colorHex: String {
        switch self {
        case .painPoint: return "#E74C3C"
        case .userNeed: return "#3498DB"
        case .delight: return "#2ECC71"
        case .workaround: return "#F39C12"
        case .featureRequest: return "#9B59B6"
        case .keyQuote: return "#1ABC9C"
        case .uncategorized: return "#95A5A6"
        }
    }
}

// MARK: - Highlight

/// A saved transcript highlight or quote from an interview session.
///
/// Highlights capture notable moments from transcripts and organize them
/// by category for cross-session analysis in the Quote Library.
///
/// Persisted as JSON by `HighlightService` rather than as a SwiftData model.
struct Highlight: Identifiable, Codable, Equatable {

    /// Unique identifier for the highlight
    let id: UUID

    /// Short descriptive title for the highlight
    var title: String

    /// The quoted text from the transcript
    var quoteText: String

    /// Display name of the speaker (e.g., "Participant", "Interviewer")
    var speaker: String

    /// Category for organizing and filtering
    var category: HighlightCategory

    /// Researcher notes about this highlight
    var notes: String

    /// Whether this highlight is starred/favorited
    var isStarred: Bool

    /// The ID of the source utterance in the transcript
    let utteranceId: UUID

    /// The ID of the session this highlight was created from
    let sessionId: UUID

    /// Timestamp in seconds from the start of the session
    let timestampSeconds: Double

    /// When this highlight was created
    let createdAt: Date

    /// When this highlight was last modified
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        quoteText: String,
        speaker: String,
        category: HighlightCategory = .uncategorized,
        notes: String = "",
        isStarred: Bool = false,
        utteranceId: UUID,
        sessionId: UUID,
        timestampSeconds: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.quoteText = quoteText
        self.speaker = speaker
        self.category = category
        self.notes = notes
        self.isStarred = isStarred
        self.utteranceId = utteranceId
        self.sessionId = sessionId
        self.timestampSeconds = timestampSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Formatted timestamp string (MM:SS)
    var formattedTimestamp: String {
        let minutes = Int(timestampSeconds) / 60
        let seconds = Int(timestampSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Equatable

    static func == (lhs: Highlight, rhs: Highlight) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension Highlight: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
