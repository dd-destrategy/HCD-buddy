//
//  InsightFlaggingService.swift
//  HCDInterviewCoach
//
//  EPIC E8: Insight Flagging
//  Service for manual and automatic insight flagging
//

import Foundation
import Combine
import SwiftData

// MARK: - Insight Flagging Service

/// Service responsible for creating, managing, and automatically flagging insights during sessions.
/// Supports both manual flagging via keyboard shortcuts and automatic AI-based flagging.
///
/// Usage:
/// ```swift
/// let service = InsightFlaggingService(session: currentSession, dataManager: dataManager)
/// service.flagManually(utterance: utterance, title: "Key insight")
/// ```
@MainActor
class InsightFlaggingService: ObservableObject {

    // MARK: - Published Properties

    /// All insights for the current session, sorted by timestamp
    @Published private(set) var insights: [Insight] = []

    /// Whether auto-flagging is enabled
    @Published var autoFlaggingEnabled: Bool = true

    /// Last flagged insight (for undo support)
    @Published private(set) var lastFlaggedInsight: Insight?

    /// Current flagging status for UI feedback
    @Published private(set) var flaggingStatus: FlaggingStatus = .idle

    // MARK: - Dependencies

    private weak var session: Session?
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Auto-Flagging Configuration

    /// Keywords that trigger automatic insight flagging
    private let autoFlagKeywords: Set<String> = [
        "pain point",
        "frustrating",
        "love",
        "hate",
        "wish",
        "need",
        "want",
        "problem",
        "difficult",
        "easy",
        "confused",
        "surprised",
        "expected",
        "unexpected",
        "always",
        "never",
        "important",
        "critical",
        "worry",
        "concern",
        "delight",
        "amazing",
        "terrible",
        "perfect",
        "ideal",
        "worst",
        "best"
    ]

    /// Phrases that indicate strong sentiment
    private let sentimentPhrases: Set<String> = [
        "i really",
        "i absolutely",
        "i definitely",
        "i strongly",
        "this is why",
        "the main reason",
        "most important",
        "biggest challenge",
        "biggest problem",
        "game changer",
        "deal breaker",
        "must have",
        "can't live without"
    ]

    /// Minimum word count for auto-flagging consideration
    private let minimumWordCount = 10

    // MARK: - Initialization

    /// Creates a new InsightFlaggingService
    /// - Parameters:
    ///   - session: The current session to flag insights for
    ///   - dataManager: Data manager for persistence
    init(session: Session?, dataManager: DataManager = .shared) {
        self.session = session
        self.dataManager = dataManager
        loadInsights()
    }

    // MARK: - Public Methods

    /// Manually flags an utterance as an insight
    /// - Parameters:
    ///   - utterance: The utterance to flag
    ///   - title: Optional title for the insight (defaults to auto-generated)
    ///   - notes: Optional notes about the insight
    /// - Returns: The created insight
    @discardableResult
    func flagManually(
        utterance: Utterance,
        title: String? = nil,
        notes: String? = nil
    ) -> Insight {
        flaggingStatus = .flagging

        let insight = Insight(
            timestampSeconds: utterance.timestampSeconds,
            quote: utterance.text,
            theme: title ?? generateTheme(from: utterance.text),
            source: .userAdded,
            tags: extractTags(from: utterance.text)
        )

        // Link to session
        insight.session = session

        // Persist
        dataManager.mainContext.insert(insight)
        saveAndReload()

        lastFlaggedInsight = insight
        flaggingStatus = .flagged(insight)

        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.flaggingStatus = .idle
        }

        AppLogger.shared.info("Manually flagged insight at \(utterance.formattedTimestamp)")

        return insight
    }

    /// Manually flags at the current timestamp without a specific utterance
    /// - Parameters:
    ///   - timestamp: The timestamp in seconds
    ///   - quote: The text to quote
    ///   - title: Optional title for the insight
    /// - Returns: The created insight
    @discardableResult
    func flagAtTimestamp(
        _ timestamp: Double,
        quote: String,
        title: String? = nil
    ) -> Insight {
        flaggingStatus = .flagging

        let insight = Insight(
            timestampSeconds: timestamp,
            quote: quote,
            theme: title ?? generateTheme(from: quote),
            source: .userAdded,
            tags: extractTags(from: quote)
        )

        insight.session = session
        dataManager.mainContext.insert(insight)
        saveAndReload()

        lastFlaggedInsight = insight
        flaggingStatus = .flagged(insight)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.flaggingStatus = .idle
        }

        return insight
    }

    /// Automatically flags an utterance based on AI/pattern detection
    /// - Parameters:
    ///   - utterance: The utterance to flag
    ///   - reason: The reason for automatic flagging
    /// - Returns: The created insight, or nil if flagging was skipped
    @discardableResult
    func flagAutomatically(
        utterance: Utterance,
        reason: String
    ) -> Insight? {
        guard autoFlaggingEnabled else { return nil }

        // Check if already flagged
        if isUtteranceAlreadyFlagged(utterance) {
            return nil
        }

        let insight = Insight(
            timestampSeconds: utterance.timestampSeconds,
            quote: utterance.text,
            theme: reason,
            source: .aiGenerated,
            tags: extractTags(from: utterance.text)
        )

        insight.session = session
        dataManager.mainContext.insert(insight)
        saveAndReload()

        AppLogger.shared.info("Auto-flagged insight: \(reason) at \(utterance.formattedTimestamp)")

        return insight
    }

    /// Evaluates an utterance for automatic flagging potential
    /// - Parameter utterance: The utterance to evaluate
    /// - Returns: Flagging recommendation if the utterance should be flagged
    func evaluateForAutoFlagging(_ utterance: Utterance) -> AutoFlagRecommendation? {
        guard autoFlaggingEnabled else { return nil }
        guard utterance.wordCount >= minimumWordCount else { return nil }
        guard !isUtteranceAlreadyFlagged(utterance) else { return nil }

        let textLower = utterance.text.lowercased()

        // Check for keyword matches
        var matchedKeywords: [String] = []
        for keyword in autoFlagKeywords {
            if textLower.contains(keyword) {
                matchedKeywords.append(keyword)
            }
        }

        // Check for sentiment phrases
        var matchedPhrases: [String] = []
        for phrase in sentimentPhrases {
            if textLower.contains(phrase) {
                matchedPhrases.append(phrase)
            }
        }

        // Calculate confidence score
        let keywordScore = min(Double(matchedKeywords.count) * 0.2, 0.6)
        let phraseScore = min(Double(matchedPhrases.count) * 0.3, 0.6)
        let lengthBonus = utterance.wordCount > 25 ? 0.1 : 0
        let confidence = keywordScore + phraseScore + lengthBonus

        // Only recommend if confidence is above threshold
        guard confidence >= 0.3 else { return nil }

        // Generate reason based on matches
        let reason = generateAutoFlagReason(keywords: matchedKeywords, phrases: matchedPhrases)

        return AutoFlagRecommendation(
            utterance: utterance,
            reason: reason,
            confidence: confidence,
            matchedKeywords: matchedKeywords,
            matchedPhrases: matchedPhrases
        )
    }

    /// Removes an insight
    /// - Parameter insight: The insight to remove
    func removeInsight(_ insight: Insight) {
        dataManager.mainContext.delete(insight)
        saveAndReload()

        if lastFlaggedInsight?.id == insight.id {
            lastFlaggedInsight = nil
        }

        AppLogger.shared.info("Removed insight at \(insight.formattedTimestamp)")
    }

    /// Updates an existing insight
    /// - Parameters:
    ///   - insight: The insight to update
    ///   - title: New title (optional)
    ///   - notes: New notes (optional, stored in tags for now)
    ///   - tags: New tags (optional)
    func updateInsight(
        _ insight: Insight,
        title: String? = nil,
        notes: String? = nil,
        tags: [String]? = nil
    ) {
        if let title = title {
            insight.theme = title
        }
        if let tags = tags {
            insight.tags = tags
        }
        saveAndReload()

        AppLogger.shared.info("Updated insight: \(insight.theme)")
    }

    /// Undoes the last flagging action
    /// - Returns: True if undo was successful
    @discardableResult
    func undoLastFlag() -> Bool {
        guard let insight = lastFlaggedInsight else { return false }

        removeInsight(insight)
        lastFlaggedInsight = nil

        AppLogger.shared.info("Undid last flag")
        return true
    }

    /// Clears all auto-generated insights
    func clearAutoGeneratedInsights() {
        let autoInsights = insights.filter { $0.isAIGenerated }
        for insight in autoInsights {
            dataManager.mainContext.delete(insight)
        }
        saveAndReload()

        AppLogger.shared.info("Cleared \(autoInsights.count) auto-generated insights")
    }

    /// Refreshes insights from the data store
    func refresh() {
        loadInsights()
    }

    // MARK: - Query Methods

    /// Returns insights filtered by source type
    func insights(bySource source: InsightSource) -> [Insight] {
        insights.filter { $0.source == source }
    }

    /// Returns insights within a time range
    func insights(from startTime: Double, to endTime: Double) -> [Insight] {
        insights.filter { $0.timestampSeconds >= startTime && $0.timestampSeconds <= endTime }
    }

    /// Finds the insight closest to a given timestamp
    func nearestInsight(to timestamp: Double) -> Insight? {
        insights.min { abs($0.timestampSeconds - timestamp) < abs($1.timestampSeconds - timestamp) }
    }

    /// Checks if an utterance has already been flagged
    func isUtteranceAlreadyFlagged(_ utterance: Utterance) -> Bool {
        // Check if there's an insight within 2 seconds with similar text
        insights.contains { insight in
            abs(insight.timestampSeconds - utterance.timestampSeconds) < 2.0 ||
            insight.quote == utterance.text
        }
    }

    // MARK: - Private Methods

    private func loadInsights() {
        guard let session = session else {
            insights = []
            return
        }

        insights = session.insights.sorted { $0.timestampSeconds < $1.timestampSeconds }
    }

    private func saveAndReload() {
        do {
            try dataManager.save()
            loadInsights()
        } catch {
            AppLogger.shared.error("Failed to save insight: \(error.localizedDescription)")
        }
    }

    private func generateTheme(from text: String) -> String {
        // Generate a short theme/title from the text
        let words = text.split(separator: " ")

        // Check for key phrases first
        let textLower = text.lowercased()

        if textLower.contains("pain point") || textLower.contains("frustrat") {
            return "Pain Point"
        } else if textLower.contains("wish") || textLower.contains("want") || textLower.contains("need") {
            return "User Need"
        } else if textLower.contains("love") || textLower.contains("delight") || textLower.contains("amazing") {
            return "Positive Moment"
        } else if textLower.contains("confus") || textLower.contains("unclear") {
            return "Confusion Point"
        } else if textLower.contains("suggest") || textLower.contains("idea") {
            return "User Suggestion"
        } else if textLower.contains("expect") {
            return "Expectation"
        } else if textLower.contains("surprise") {
            return "Surprising Finding"
        }

        // Default: use first few words
        let maxWords = min(5, words.count)
        let preview = words.prefix(maxWords).joined(separator: " ")
        return preview + (words.count > maxWords ? "..." : "")
    }

    private func extractTags(from text: String) -> [String] {
        var tags: [String] = []
        let textLower = text.lowercased()

        // Extract thematic tags
        if textLower.contains("pain") || textLower.contains("frustrat") || textLower.contains("difficult") {
            tags.append("pain-point")
        }
        if textLower.contains("need") || textLower.contains("want") || textLower.contains("wish") {
            tags.append("user-need")
        }
        if textLower.contains("love") || textLower.contains("great") || textLower.contains("perfect") {
            tags.append("positive")
        }
        if textLower.contains("confus") || textLower.contains("unclear") || textLower.contains("don't understand") {
            tags.append("confusion")
        }
        if textLower.contains("suggest") || textLower.contains("idea") || textLower.contains("what if") {
            tags.append("suggestion")
        }
        if textLower.contains("workflow") || textLower.contains("process") || textLower.contains("step") {
            tags.append("workflow")
        }

        return tags
    }

    private func generateAutoFlagReason(keywords: [String], phrases: [String]) -> String {
        if !phrases.isEmpty {
            if phrases.contains("biggest challenge") || phrases.contains("biggest problem") {
                return "Key Challenge"
            } else if phrases.contains("most important") || phrases.contains("must have") {
                return "Critical Need"
            } else if phrases.contains("i really") || phrases.contains("i absolutely") {
                return "Strong Opinion"
            }
        }

        if !keywords.isEmpty {
            let keyword = keywords.first!
            switch keyword {
            case "pain point", "frustrating", "difficult", "problem":
                return "Pain Point"
            case "love", "delight", "amazing", "perfect":
                return "Positive Moment"
            case "need", "want", "wish":
                return "User Need"
            case "confused", "surprising", "unexpected":
                return "Notable Moment"
            case "important", "critical":
                return "Important Point"
            default:
                return "Notable Moment"
            }
        }

        return "Notable Moment"
    }
}

// MARK: - Supporting Types

/// Status of the flagging operation
enum FlaggingStatus: Equatable {
    case idle
    case flagging
    case flagged(Insight)
    case error(String)

    static func == (lhs: FlaggingStatus, rhs: FlaggingStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.flagging, .flagging):
            return true
        case (.flagged(let lhsInsight), .flagged(let rhsInsight)):
            return lhsInsight.id == rhsInsight.id
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Recommendation for automatic flagging
struct AutoFlagRecommendation {
    let utterance: Utterance
    let reason: String
    let confidence: Double
    let matchedKeywords: [String]
    let matchedPhrases: [String]

    /// Human-readable confidence level
    var confidenceLevel: String {
        switch confidence {
        case 0.7...:
            return "High"
        case 0.5..<0.7:
            return "Medium"
        default:
            return "Low"
        }
    }
}

// MARK: - Insight Flagging Service Factory

/// Factory for creating InsightFlaggingService instances
@MainActor
struct InsightFlaggingServiceFactory {

    /// Creates a flagging service for the given session
    static func create(for session: Session?, dataManager: DataManager = .shared) -> InsightFlaggingService {
        InsightFlaggingService(session: session, dataManager: dataManager)
    }
}
