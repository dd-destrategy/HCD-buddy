//
//  FollowUpSuggester.swift
//  HCD Interview Coach
//
//  FollowUpSuggester: Generates contextual follow-up question suggestions
//  Based on participant's last statement and interview template methodology
//  Non-intrusive sidebar display, researcher pulls on demand
//

import Foundation
import Combine

// MARK: - Suggestion Category

/// Categories of follow-up question suggestions
enum SuggestionCategory: String, CaseIterable {
    /// Dig deeper into a topic the participant mentioned
    case probeDeeper = "probe_deeper"

    /// Explore emotional aspects of the participant's statement
    case emotionExplore = "emotion_explore"

    /// Ask for clarification on unclear or jargon terms
    case clarify = "clarify"

    /// Redirect conversation toward an uncovered topic
    case redirectToTopic = "redirect_to_topic"

    /// Explore timeline or sequence of events
    case timelineExplore = "timeline_explore"

    /// Explore comparisons or contrasts mentioned
    case contrastExplore = "contrast_explore"

    var displayName: String {
        switch self {
        case .probeDeeper: return "Probe Deeper"
        case .emotionExplore: return "Explore Emotion"
        case .clarify: return "Clarify"
        case .redirectToTopic: return "Redirect to Topic"
        case .timelineExplore: return "Timeline"
        case .contrastExplore: return "Contrast"
        }
    }

    var icon: String {
        switch self {
        case .probeDeeper: return "magnifyingglass"
        case .emotionExplore: return "heart"
        case .clarify: return "questionmark.circle"
        case .redirectToTopic: return "arrow.triangle.turn.up.right.circle"
        case .timelineExplore: return "clock.arrow.circlepath"
        case .contrastExplore: return "arrow.left.arrow.right"
        }
    }

    var colorName: String {
        switch self {
        case .probeDeeper: return "purple"
        case .emotionExplore: return "pink"
        case .clarify: return "cyan"
        case .redirectToTopic: return "orange"
        case .timelineExplore: return "blue"
        case .contrastExplore: return "indigo"
        }
    }
}

// MARK: - Follow-Up Suggestion

/// A generated follow-up question suggestion for the interviewer
struct FollowUpSuggestion: Identifiable {
    let id: UUID
    let text: String
    let category: SuggestionCategory
    let relevance: Double
    let triggerQuote: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        category: SuggestionCategory,
        relevance: Double,
        triggerQuote: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.relevance = relevance
        self.triggerQuote = triggerQuote
        self.createdAt = createdAt
    }
}

// MARK: - Follow-Up Suggester

/// Generates contextual follow-up question suggestions based on participant statements.
///
/// Uses rules-based analysis (no external API calls) to detect patterns in
/// participant utterances and generate relevant follow-up question suggestions.
/// Supports both automatic generation on each participant utterance and manual triggers.
@MainActor
final class FollowUpSuggester: ObservableObject {

    // MARK: - Published Properties

    /// Current list of follow-up suggestions
    @Published private(set) var suggestions: [FollowUpSuggestion] = []

    /// Whether the suggester is currently generating suggestions
    @Published private(set) var isGenerating: Bool = false

    /// Maximum number of suggestions to show at once
    @Published var maxSuggestions: Int = 3

    /// Whether the suggester is enabled
    @Published var isEnabled: Bool = true

    /// Whether to auto-generate on each participant utterance
    @Published var autoGenerate: Bool = true

    // MARK: - Private Properties

    /// Tracks accepted suggestion IDs for analytics
    private var acceptedSuggestionIds: Set<UUID> = []

    /// Tracks dismissed suggestion IDs
    private var dismissedSuggestionIds: Set<UUID> = []

    // MARK: - Emotion Detection Words

    private let emotionWords: [String] = [
        "frustrated", "frustrating", "frustration",
        "happy", "happiness", "glad",
        "angry", "anger", "annoyed", "annoying",
        "confused", "confusing", "confusion",
        "excited", "exciting", "excitement",
        "worried", "worrying", "worry", "anxious", "anxiety",
        "stressed", "stressful", "stress",
        "disappointed", "disappointing", "disappointment",
        "surprised", "surprising", "surprise",
        "scared", "scary", "afraid", "fear",
        "overwhelmed", "overwhelming",
        "relieved", "relief",
        "satisfied", "satisfying", "satisfaction",
        "uncomfortable", "uncomfortable",
        "confident", "confidence",
        "nervous", "nervousness",
        "delighted", "thrilled", "upset",
        "love", "loved", "hate", "hated",
        "enjoy", "enjoyed", "dread", "dreaded",
        "felt", "feeling", "feel"
    ]

    // MARK: - Process / Timeline Words

    private let processWords: [String] = [
        "first", "then", "next", "after that", "finally",
        "started", "began", "ended up", "eventually",
        "step by step", "process", "procedure", "workflow",
        "went through", "followed", "sequence",
        "before", "during", "after", "while",
        "led to", "resulted in", "caused",
        "tried to", "attempted", "managed to"
    ]

    // MARK: - Comparison / Contrast Words

    private let comparisonWords: [String] = [
        "compared to", "unlike", "different from",
        "better than", "worse than", "similar to",
        "on the other hand", "in contrast", "whereas",
        "but", "however", "although",
        "used to", "now I", "before I would",
        "switched from", "moved from", "changed to",
        "prefer", "rather", "instead of"
    ]

    // MARK: - Jargon / Unclear Language Indicators

    private let jargonIndicators: [String] = [
        "basically", "essentially", "sort of", "kind of",
        "you know", "like,", "i mean", "it's like",
        "that thing", "the stuff", "whatever",
        "hard to explain", "difficult to describe",
        "i guess", "i suppose", "maybe"
    ]

    // MARK: - Short Answer Threshold

    /// Word count below which an answer is considered short
    private let shortAnswerThreshold: Int = 8

    // MARK: - Public Methods

    /// Generate follow-up suggestions based on a participant utterance.
    ///
    /// Analyzes the utterance text for emotion words, process descriptions,
    /// comparisons, short answers, and unclear language, then generates
    /// relevant suggestions up to `maxSuggestions`.
    ///
    /// - Parameters:
    ///   - utterance: The participant's utterance to analyze
    ///   - topics: List of uncovered or relevant topics for the interview
    func generateSuggestions(from utterance: Utterance, topics: [String] = []) {
        guard isEnabled else { return }
        guard utterance.speaker == .participant else { return }

        let text = utterance.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isGenerating = true

        let lowercased = text.lowercased()
        var newSuggestions: [FollowUpSuggestion] = []

        // 1. Emotion detection
        if let emotionSuggestion = generateEmotionSuggestion(text: text, lowercased: lowercased) {
            newSuggestions.append(emotionSuggestion)
        }

        // 2. Process / timeline detection
        if let timelineSuggestion = generateTimelineSuggestion(text: text, lowercased: lowercased) {
            newSuggestions.append(timelineSuggestion)
        }

        // 3. Comparison / contrast detection
        if let contrastSuggestion = generateContrastSuggestion(text: text, lowercased: lowercased) {
            newSuggestions.append(contrastSuggestion)
        }

        // 4. Jargon / unclear language detection
        if let clarifySuggestion = generateClarifySuggestion(text: text, lowercased: lowercased) {
            newSuggestions.append(clarifySuggestion)
        }

        // 5. Short answer detection (suggest elaboration)
        if newSuggestions.isEmpty || utterance.wordCount <= shortAnswerThreshold {
            if let elaborationSuggestion = generateElaborationSuggestion(text: text, wordCount: utterance.wordCount) {
                newSuggestions.append(elaborationSuggestion)
            }
        }

        // 6. Topic redirect (if uncovered topics remain)
        if let topicSuggestion = generateTopicRedirectSuggestion(text: text, topics: topics) {
            newSuggestions.append(topicSuggestion)
        }

        // Sort by relevance and limit to maxSuggestions
        newSuggestions.sort { $0.relevance > $1.relevance }
        suggestions = Array(newSuggestions.prefix(maxSuggestions))

        isGenerating = false
    }

    /// Dismiss a specific suggestion by ID
    /// - Parameter id: The UUID of the suggestion to dismiss
    func dismissSuggestion(_ id: UUID) {
        dismissedSuggestionIds.insert(id)
        suggestions.removeAll { $0.id == id }
    }

    /// Dismiss all current suggestions
    func dismissAll() {
        for suggestion in suggestions {
            dismissedSuggestionIds.insert(suggestion.id)
        }
        suggestions.removeAll()
    }

    /// Accept a suggestion, logging it for analytics
    /// - Parameter id: The UUID of the accepted suggestion
    func acceptSuggestion(_ id: UUID) {
        acceptedSuggestionIds.insert(id)
        suggestions.removeAll { $0.id == id }
    }

    /// Reset all state for a new session
    func reset() {
        suggestions.removeAll()
        acceptedSuggestionIds.removeAll()
        dismissedSuggestionIds.removeAll()
        isGenerating = false
    }

    // MARK: - Analytics Properties

    /// Total number of suggestions that have been accepted
    var totalAccepted: Int {
        acceptedSuggestionIds.count
    }

    /// Total number of suggestions that have been dismissed
    var totalDismissed: Int {
        dismissedSuggestionIds.count
    }

    // MARK: - Private Generation Methods

    /// Generate a suggestion to explore emotion
    private func generateEmotionSuggestion(text: String, lowercased: String) -> FollowUpSuggestion? {
        var detectedEmotion: String?

        for word in emotionWords {
            if lowercased.contains(word) {
                detectedEmotion = word
                break
            }
        }

        guard let emotion = detectedEmotion else { return nil }

        // Extract a short quote around the emotion word
        let triggerQuote = extractTriggerQuote(from: text, around: emotion)

        // Generate contextual suggestion
        let suggestionText: String
        switch emotion {
        case "frustrated", "frustrating", "frustration":
            suggestionText = "You mentioned feeling frustrated. Can you walk me through what made that experience so frustrating?"
        case "confused", "confusing", "confusion":
            suggestionText = "You mentioned some confusion. What specifically was unclear or confusing about that?"
        case "excited", "exciting", "excitement":
            suggestionText = "That sounds like it was exciting for you. What made that moment stand out?"
        case "worried", "worrying", "worry", "anxious", "anxiety":
            suggestionText = "You mentioned some concern about that. What were you most worried about?"
        case "surprised", "surprising", "surprise":
            suggestionText = "You seemed surprised by that. What were you expecting instead?"
        case "overwhelmed", "overwhelming":
            suggestionText = "That sounds like it was a lot to handle. What would have made that more manageable?"
        case "felt", "feeling", "feel":
            suggestionText = "You mentioned how you felt about that. Can you describe that feeling in more detail?"
        default:
            suggestionText = "You mentioned feeling \(emotion). Can you walk me through that moment and what led to that feeling?"
        }

        return FollowUpSuggestion(
            text: suggestionText,
            category: .emotionExplore,
            relevance: 0.90,
            triggerQuote: triggerQuote
        )
    }

    /// Generate a suggestion to explore timeline or process
    private func generateTimelineSuggestion(text: String, lowercased: String) -> FollowUpSuggestion? {
        var detectedProcess: String?

        for word in processWords {
            if lowercased.contains(word) {
                detectedProcess = word
                break
            }
        }

        guard let process = detectedProcess else { return nil }

        let triggerQuote = extractTriggerQuote(from: text, around: process)

        let suggestionText: String
        switch process {
        case "first", "started", "began":
            suggestionText = "You mentioned how this started. What happened next after that initial step?"
        case "finally", "ended up", "eventually":
            suggestionText = "You described where you ended up. What were the key turning points along the way?"
        case "tried to", "attempted", "managed to":
            suggestionText = "You mentioned trying to do that. What challenges did you encounter along the way?"
        case "led to", "resulted in", "caused":
            suggestionText = "You described a cause and effect. What do you think was the root cause of that?"
        default:
            suggestionText = "It sounds like there was a process involved. Could you walk me through that step by step?"
        }

        return FollowUpSuggestion(
            text: suggestionText,
            category: .timelineExplore,
            relevance: 0.80,
            triggerQuote: triggerQuote
        )
    }

    /// Generate a suggestion to explore contrast or comparison
    private func generateContrastSuggestion(text: String, lowercased: String) -> FollowUpSuggestion? {
        var detectedComparison: String?

        for word in comparisonWords {
            if lowercased.contains(word) {
                detectedComparison = word
                break
            }
        }

        guard let comparison = detectedComparison else { return nil }

        let triggerQuote = extractTriggerQuote(from: text, around: comparison)

        let suggestionText: String
        switch comparison {
        case "compared to", "similar to", "different from":
            suggestionText = "You drew a comparison there. What specifically makes those different in your experience?"
        case "better than", "worse than":
            suggestionText = "You mentioned one being better or worse. What specific aspects make you feel that way?"
        case "used to", "now I", "before I would":
            suggestionText = "It sounds like things have changed over time. What prompted that shift in your approach?"
        case "switched from", "moved from", "changed to":
            suggestionText = "You mentioned making a change. What drove that decision, and how has it worked out?"
        case "prefer", "rather", "instead of":
            suggestionText = "You mentioned a preference. What about that option makes it work better for you?"
        default:
            suggestionText = "You made an interesting comparison. How do those two experiences differ for you?"
        }

        return FollowUpSuggestion(
            text: suggestionText,
            category: .contrastExplore,
            relevance: 0.75,
            triggerQuote: triggerQuote
        )
    }

    /// Generate a suggestion to clarify jargon or unclear language
    private func generateClarifySuggestion(text: String, lowercased: String) -> FollowUpSuggestion? {
        var detectedJargon: String?

        for indicator in jargonIndicators {
            if lowercased.contains(indicator) {
                detectedJargon = indicator
                break
            }
        }

        guard let jargon = detectedJargon else { return nil }

        let triggerQuote = extractTriggerQuote(from: text, around: jargon)

        let suggestionText: String
        switch jargon {
        case "basically", "essentially":
            suggestionText = "Could you unpack that a bit more? What does that look like in practice?"
        case "sort of", "kind of":
            suggestionText = "You said it was 'sort of' like that. Can you describe more precisely what you mean?"
        case "hard to explain", "difficult to describe":
            suggestionText = "Take your time. Maybe you could describe a specific example that illustrates what you mean?"
        case "that thing", "the stuff":
            suggestionText = "Could you tell me more specifically what you're referring to there?"
        default:
            suggestionText = "Could you help me understand what you mean by that? Can you give me a specific example?"
        }

        return FollowUpSuggestion(
            text: suggestionText,
            category: .clarify,
            relevance: 0.70,
            triggerQuote: triggerQuote
        )
    }

    /// Generate a suggestion for short or brief answers
    private func generateElaborationSuggestion(text: String, wordCount: Int) -> FollowUpSuggestion? {
        guard wordCount <= shortAnswerThreshold else { return nil }

        let triggerQuote = String(text.prefix(60))

        let suggestions = [
            "Could you tell me more about that? I'd love to hear the details.",
            "That's interesting. Can you walk me through what that experience was like?",
            "Could you elaborate on that? What specifically comes to mind?",
            "I'd like to understand more. Can you give me an example?"
        ]

        // Pick suggestion based on text hash for consistency
        let index = abs(text.hashValue) % suggestions.count
        let suggestionText = suggestions[index]

        // Higher relevance for very short answers
        let relevance = wordCount <= 3 ? 0.95 : 0.85

        return FollowUpSuggestion(
            text: suggestionText,
            category: .probeDeeper,
            relevance: relevance,
            triggerQuote: triggerQuote
        )
    }

    /// Generate a suggestion to redirect to an uncovered topic
    private func generateTopicRedirectSuggestion(text: String, topics: [String]) -> FollowUpSuggestion? {
        guard !topics.isEmpty else { return nil }

        let lowercased = text.lowercased()

        // Find a topic not already mentioned in the current utterance
        var redirectTopic: String?
        for topic in topics {
            if !lowercased.contains(topic.lowercased()) {
                redirectTopic = topic
                break
            }
        }

        guard let topic = redirectTopic else { return nil }

        let triggerQuote = String(text.prefix(50))
        let suggestionText = "That's great context. I'd also love to hear your thoughts on \(topic). How has that been for you?"

        return FollowUpSuggestion(
            text: suggestionText,
            category: .redirectToTopic,
            relevance: 0.60,
            triggerQuote: triggerQuote
        )
    }

    // MARK: - Utility Methods

    /// Extract a short quote from the text around a detected keyword
    private func extractTriggerQuote(from text: String, around keyword: String) -> String {
        let lowercased = text.lowercased()
        guard let range = lowercased.range(of: keyword) else {
            return String(text.prefix(60))
        }

        // Get position of keyword
        let keywordStart = lowercased.distance(from: lowercased.startIndex, to: range.lowerBound)
        let quoteStart = max(0, keywordStart - 20)
        let quoteEnd = min(text.count, keywordStart + keyword.count + 30)

        let startIndex = text.index(text.startIndex, offsetBy: quoteStart)
        let endIndex = text.index(text.startIndex, offsetBy: quoteEnd)

        var quote = String(text[startIndex..<endIndex]).trimmingCharacters(in: .whitespaces)

        if quoteStart > 0 {
            quote = "..." + quote
        }
        if quoteEnd < text.count {
            quote = quote + "..."
        }

        return quote
    }
}
