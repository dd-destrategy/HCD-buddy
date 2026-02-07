//
//  QuestionTypeAnalyzer.swift
//  HCD Interview Coach
//
//  QuestionTypeAnalyzer: Classifies interviewer questions into types
//  Uses NLP rules-based classification (no external API calls)
//  Detects anti-patterns (leading, double-barreled, closed runs)
//

import Foundation
import Combine

// MARK: - Question Type

/// Classification types for interviewer questions
enum QuestionType: String, CaseIterable, Codable {
    /// Open-ended questions that invite detailed responses
    /// e.g., "Tell me about...", "How do you...", "What was your experience..."
    case openEnded = "open_ended"

    /// Yes/no or specific fact questions
    /// e.g., "Do you use this?", "Is that correct?"
    case closed = "closed"

    /// Questions containing assumptions or suggesting an answer
    /// e.g., "Don't you think...", "Wouldn't you agree..."
    case leading = "leading"

    /// Two questions combined into one
    /// e.g., "Do you like the color and the size?"
    case doubleBarreled = "double_barreled"

    /// Follow-up probes seeking deeper insight
    /// e.g., "Can you tell me more?", "Why is that?"
    case probing = "probing"

    /// Questions seeking clarification of meaning
    /// e.g., "What do you mean by...", "Could you explain..."
    case clarifying = "clarifying"

    /// Scenario-based questions about imagined situations
    /// e.g., "What if...", "Imagine..."
    case hypothetical = "hypothetical"

    /// Statements or non-questions misclassified as questions
    case notAQuestion = "not_a_question"

    var displayName: String {
        switch self {
        case .openEnded: return "Open-Ended"
        case .closed: return "Closed"
        case .leading: return "Leading"
        case .doubleBarreled: return "Double-Barreled"
        case .probing: return "Probing"
        case .clarifying: return "Clarifying"
        case .hypothetical: return "Hypothetical"
        case .notAQuestion: return "Not a Question"
        }
    }

    var icon: String {
        switch self {
        case .openEnded: return "text.bubble"
        case .closed: return "circle.fill"
        case .leading: return "exclamationmark.triangle"
        case .doubleBarreled: return "arrow.triangle.branch"
        case .probing: return "magnifyingglass"
        case .clarifying: return "questionmark.circle"
        case .hypothetical: return "lightbulb"
        case .notAQuestion: return "minus.circle"
        }
    }

    /// Color name for visual indicators
    var colorName: String {
        switch self {
        case .openEnded: return "green"
        case .closed: return "blue"
        case .leading: return "red"
        case .doubleBarreled: return "orange"
        case .probing: return "purple"
        case .clarifying: return "cyan"
        case .hypothetical: return "indigo"
        case .notAQuestion: return "gray"
        }
    }

    /// Whether this type is generally considered good practice in HCD interviews
    var isDesirable: Bool {
        switch self {
        case .openEnded, .probing, .clarifying, .hypothetical:
            return true
        case .closed, .leading, .doubleBarreled, .notAQuestion:
            return false
        }
    }
}

// MARK: - Anti-Pattern

/// Detected interview anti-patterns
enum AntiPattern: String, CaseIterable {
    /// A question that leads the participant toward a specific answer
    case leadingQuestion = "leading_question"

    /// A question that asks about two things at once
    case doubleBarreledQuestion = "double_barreled_question"

    /// Three or more consecutive closed questions
    case closedQuestionRun = "closed_question_run"

    /// Language that assumes participant's experience or opinion
    case assumptiveLanguage = "assumptive_language"

    var displayName: String {
        switch self {
        case .leadingQuestion: return "Leading Question"
        case .doubleBarreledQuestion: return "Double-Barreled"
        case .closedQuestionRun: return "Closed Run"
        case .assumptiveLanguage: return "Assumptive Language"
        }
    }

    var description: String {
        switch self {
        case .leadingQuestion:
            return "This question may guide the participant toward a particular answer. Try rephrasing neutrally."
        case .doubleBarreledQuestion:
            return "This asks about multiple things at once. Split into separate questions for clearer data."
        case .closedQuestionRun:
            return "Multiple closed questions in a row. Consider an open-ended question to let the participant share freely."
        case .assumptiveLanguage:
            return "This language assumes something about the participant. Consider a more neutral framing."
        }
    }

    var icon: String {
        switch self {
        case .leadingQuestion: return "exclamationmark.triangle.fill"
        case .doubleBarreledQuestion: return "arrow.triangle.branch"
        case .closedQuestionRun: return "list.bullet"
        case .assumptiveLanguage: return "quote.opening"
        }
    }

    var severity: Int {
        switch self {
        case .leadingQuestion: return 3
        case .doubleBarreledQuestion: return 2
        case .closedQuestionRun: return 1
        case .assumptiveLanguage: return 2
        }
    }
}

// MARK: - Question Classification

/// Result of classifying an interviewer question
struct QuestionClassification: Identifiable {
    let id: UUID
    let utteranceId: UUID
    let type: QuestionType
    let confidence: Double
    let text: String
    let timestamp: TimeInterval
    let antiPatterns: [AntiPattern]

    init(
        id: UUID = UUID(),
        utteranceId: UUID,
        type: QuestionType,
        confidence: Double,
        text: String,
        timestamp: TimeInterval,
        antiPatterns: [AntiPattern] = []
    ) {
        self.id = id
        self.utteranceId = utteranceId
        self.type = type
        self.confidence = confidence
        self.text = text
        self.timestamp = timestamp
        self.antiPatterns = antiPatterns
    }
}

// MARK: - Question Stats

/// Aggregate statistics for question analysis
struct QuestionStats {
    let totalQuestions: Int
    let openEndedCount: Int
    let closedCount: Int
    let leadingCount: Int
    let doubleBarreledCount: Int
    let probingCount: Int
    let openEndedPercentage: Double
    let qualityScore: Double

    static let empty = QuestionStats(
        totalQuestions: 0,
        openEndedCount: 0,
        closedCount: 0,
        leadingCount: 0,
        doubleBarreledCount: 0,
        probingCount: 0,
        openEndedPercentage: 0,
        qualityScore: 0
    )
}

// MARK: - Question Type Analyzer

/// Classifies interviewer questions and detects anti-patterns using rules-based NLP.
///
/// The analyzer processes each interviewer utterance to determine question type,
/// tracks patterns over time, and generates quality metrics for the interview session.
@MainActor
final class QuestionTypeAnalyzer: ObservableObject {

    // MARK: - Published Properties

    /// All classifications from the current session
    @Published private(set) var classifications: [QuestionClassification] = []

    /// Aggregate session statistics
    @Published private(set) var sessionStats: QuestionStats = .empty

    /// Currently active anti-patterns (recent detections)
    @Published private(set) var currentAntiPatterns: [AntiPattern] = []

    // MARK: - Private Properties

    /// Tracks consecutive closed questions for run detection
    private var consecutiveClosedCount: Int = 0

    /// Threshold for detecting a closed question run
    private let closedRunThreshold: Int = 3

    // MARK: - Classification Patterns

    /// Patterns that indicate open-ended questions
    private let openEndedPrefixes: [String] = [
        "how ", "how do ", "how did ", "how would ", "how does ",
        "what ", "what do ", "what did ", "what was ", "what is ", "what are ",
        "tell me about", "tell me ", "describe ", "explain ",
        "walk me through", "share with me", "help me understand",
        "in what ways", "what has been", "what were"
    ]

    /// Patterns that indicate closed questions
    private let closedPrefixes: [String] = [
        "do you ", "did you ", "is it ", "is that ", "is there ",
        "are you ", "are there ", "have you ", "has it ",
        "can you ", "could you ", "was it ", "was that ",
        "will you ", "would you ", "were you ", "should ",
        "does it ", "does that ", "doesn't ", "isn't "
    ]

    /// Patterns that indicate leading questions
    private let leadingPhrases: [String] = [
        "don't you think", "wouldn't you agree", "wouldn't you say",
        "isn't it true", "isn't it obvious", "isn't it clear",
        "surely ", "obviously ", "clearly ",
        "you would agree", "you must think", "you must feel",
        "most people think", "everyone knows",
        "it's obvious that", "it's clear that",
        "right?", "correct?", "isn't it?", "don't you?"
    ]

    /// Patterns that indicate assumptive language
    private let assumptivePhrases: [String] = [
        "you must have felt", "you probably think",
        "i'm sure you", "i assume you", "i bet you",
        "you obviously", "you clearly", "you definitely",
        "of course you", "naturally you"
    ]

    /// Patterns that indicate probing questions
    private let probingPrefixes: [String] = [
        "why ", "why do ", "why did ", "why is ", "why was ",
        "tell me more", "can you elaborate", "could you elaborate",
        "what else", "how so", "in what way",
        "what makes you", "what led you", "what prompted",
        "can you give me an example", "could you give me an example",
        "what do you mean when you say"
    ]

    /// Patterns that indicate clarifying questions
    private let clarifyingPhrases: [String] = [
        "what do you mean", "what does that mean",
        "could you explain", "can you explain",
        "what does that", "what did you mean",
        "clarify", "help me understand what",
        "when you say", "by that do you mean",
        "i want to make sure i understand"
    ]

    /// Patterns that indicate hypothetical questions
    private let hypotheticalPrefixes: [String] = [
        "what if ", "what would ", "imagine ",
        "suppose ", "let's say ", "lets say ",
        "hypothetically", "if you could ", "if you were ",
        "in an ideal world", "if there were no constraints"
    ]

    // MARK: - Double-Barreled Detection

    /// Conjunctions that may indicate double-barreled questions
    private let doubleBarrelConjunctions: [String] = [
        " and do you ", " and how ", " and what ", " and why ",
        " and did you ", " and are you ", " and is it ",
        " or do you ", " or would you ", " as well as "
    ]

    // MARK: - Public Methods

    /// Classify an utterance and return its classification.
    ///
    /// Only processes interviewer utterances that appear to be questions.
    /// Participant utterances and non-questions are ignored.
    ///
    /// - Parameter utterance: The utterance to classify
    /// - Returns: A classification result, or nil if the utterance is not an interviewer question
    func classify(_ utterance: Utterance) -> QuestionClassification? {
        // Only classify interviewer utterances
        guard utterance.speaker == .interviewer else {
            return nil
        }

        let text = utterance.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        let lowercased = text.lowercased()

        // Determine if this is a question
        let isQuestion = detectIsQuestion(text: text, lowercased: lowercased)

        guard isQuestion else {
            // Reset consecutive closed count for non-questions
            consecutiveClosedCount = 0
            return nil
        }

        // Classify the question type
        var detectedType = classifyQuestionType(lowercased: lowercased)
        var confidence = calculateConfidence(for: detectedType, lowercased: lowercased)
        var antiPatterns: [AntiPattern] = []

        // Check for anti-patterns (these can override or supplement the type)
        let hasLeadingLanguage = detectLeadingLanguage(lowercased: lowercased)
        let hasAssumptiveLanguage = detectAssumptiveLanguage(lowercased: lowercased)
        let isDoubleBarreled = detectDoubleBarreled(lowercased: lowercased)

        if hasLeadingLanguage {
            detectedType = .leading
            confidence = max(confidence, 0.85)
            antiPatterns.append(.leadingQuestion)
        }

        if hasAssumptiveLanguage {
            antiPatterns.append(.assumptiveLanguage)
            if detectedType != .leading {
                confidence = max(confidence, 0.75)
            }
        }

        if isDoubleBarreled {
            detectedType = .doubleBarreled
            confidence = max(confidence, 0.80)
            antiPatterns.append(.doubleBarreledQuestion)
        }

        // Track consecutive closed questions
        if detectedType == .closed {
            consecutiveClosedCount += 1
            if consecutiveClosedCount >= closedRunThreshold {
                antiPatterns.append(.closedQuestionRun)
            }
        } else {
            consecutiveClosedCount = 0
        }

        let classification = QuestionClassification(
            utteranceId: utterance.id,
            type: detectedType,
            confidence: confidence,
            text: text,
            timestamp: utterance.timestampSeconds,
            antiPatterns: antiPatterns
        )

        // Update published state
        classifications.append(classification)
        updateStats()
        updateCurrentAntiPatterns(from: classification)

        return classification
    }

    /// Reset all analysis state for a new session
    func reset() {
        classifications.removeAll()
        sessionStats = .empty
        currentAntiPatterns.removeAll()
        consecutiveClosedCount = 0
    }

    // MARK: - Private Classification Methods

    /// Detect whether the text appears to be a question
    private func detectIsQuestion(text: String, lowercased: String) -> Bool {
        // Direct check: ends with question mark
        if text.hasSuffix("?") {
            return true
        }

        // Check if it starts with an interrogative word or phrase
        let interrogativePrefixes: [String] = [
            "how ", "what ", "when ", "where ", "why ", "who ", "which ",
            "do ", "did ", "is ", "are ", "have ", "has ", "can ", "could ",
            "was ", "were ", "will ", "would ", "should ", "shall ",
            "does ", "tell me", "describe ", "explain "
        ]

        for prefix in interrogativePrefixes {
            if lowercased.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }

    /// Classify the question into its primary type
    private func classifyQuestionType(lowercased: String) -> QuestionType {
        // Check hypothetical first (very specific patterns)
        for prefix in hypotheticalPrefixes {
            if lowercased.hasPrefix(prefix) || lowercased.contains(prefix) {
                return .hypothetical
            }
        }

        // Check clarifying
        for phrase in clarifyingPhrases {
            if lowercased.contains(phrase) {
                return .clarifying
            }
        }

        // Check probing
        for prefix in probingPrefixes {
            if lowercased.hasPrefix(prefix) || lowercased.contains(prefix) {
                return .probing
            }
        }

        // Check open-ended
        for prefix in openEndedPrefixes {
            if lowercased.hasPrefix(prefix) {
                return .openEnded
            }
        }

        // Check closed
        for prefix in closedPrefixes {
            if lowercased.hasPrefix(prefix) {
                return .closed
            }
        }

        // Default: if it's a question but doesn't match known patterns,
        // classify based on whether it ends with a question mark
        return .closed
    }

    /// Calculate confidence score for the classification
    private func calculateConfidence(for type: QuestionType, lowercased: String) -> Double {
        switch type {
        case .openEnded:
            // Strong pattern match for open-ended starters
            if lowercased.hasPrefix("tell me about") || lowercased.hasPrefix("walk me through") {
                return 0.95
            }
            if lowercased.hasPrefix("how ") || lowercased.hasPrefix("what ") {
                return 0.85
            }
            return 0.75

        case .closed:
            if lowercased.hasPrefix("do you ") || lowercased.hasPrefix("did you ") {
                return 0.90
            }
            if lowercased.hasPrefix("is ") || lowercased.hasPrefix("are ") {
                return 0.85
            }
            return 0.70

        case .leading:
            return 0.90

        case .doubleBarreled:
            return 0.80

        case .probing:
            if lowercased.hasPrefix("why ") || lowercased.contains("tell me more") {
                return 0.90
            }
            return 0.80

        case .clarifying:
            if lowercased.contains("what do you mean") {
                return 0.95
            }
            return 0.85

        case .hypothetical:
            if lowercased.hasPrefix("what if ") || lowercased.hasPrefix("imagine ") {
                return 0.90
            }
            return 0.80

        case .notAQuestion:
            return 0.60
        }
    }

    /// Detect leading language in the question
    private func detectLeadingLanguage(lowercased: String) -> Bool {
        for phrase in leadingPhrases {
            if lowercased.contains(phrase) {
                return true
            }
        }
        return false
    }

    /// Detect assumptive language in the question
    private func detectAssumptiveLanguage(lowercased: String) -> Bool {
        for phrase in assumptivePhrases {
            if lowercased.contains(phrase) {
                return true
            }
        }
        return false
    }

    /// Detect double-barreled question structure
    private func detectDoubleBarreled(lowercased: String) -> Bool {
        // Check for conjunction patterns that suggest two questions in one
        for conjunction in doubleBarrelConjunctions {
            if lowercased.contains(conjunction) {
                return true
            }
        }

        // Check for multiple question marks
        let questionMarkCount = lowercased.filter { $0 == "?" }.count
        if questionMarkCount >= 2 {
            return true
        }

        // Check for " and " with question-like structure on both sides
        if lowercased.contains(" and ") {
            let parts = lowercased.components(separatedBy: " and ")
            if parts.count >= 2 {
                let firstHasInterrogative = containsInterrogativeWord(parts[0])
                let secondHasInterrogative = containsInterrogativeWord(parts[1])
                if firstHasInterrogative && secondHasInterrogative {
                    return true
                }
            }
        }

        return false
    }

    /// Check if text contains an interrogative word
    private func containsInterrogativeWord(_ text: String) -> Bool {
        let interrogatives = ["how", "what", "when", "where", "why", "who", "which",
                              "do ", "did ", "is ", "are ", "have ", "can ", "could ",
                              "would ", "should "]
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        for word in interrogatives {
            if trimmed.contains(word) {
                return true
            }
        }
        return false
    }

    // MARK: - Stats Update

    /// Recalculate session statistics from all classifications
    private func updateStats() {
        let total = classifications.count
        guard total > 0 else {
            sessionStats = .empty
            return
        }

        let openEnded = classifications.filter { $0.type == .openEnded }.count
        let closed = classifications.filter { $0.type == .closed }.count
        let leading = classifications.filter { $0.type == .leading }.count
        let doubleBarreled = classifications.filter { $0.type == .doubleBarreled }.count
        let probing = classifications.filter { $0.type == .probing }.count

        let openEndedPercentage = Double(openEnded) / Double(total) * 100.0

        // Quality score: higher when more open-ended/probing, lower for leading/double-barreled
        let desirableCount = classifications.filter { $0.type.isDesirable }.count
        let penaltyCount = leading + doubleBarreled
        let baseScore = Double(desirableCount) / Double(total) * 100.0
        let penalty = Double(penaltyCount) / Double(total) * 30.0
        let qualityScore = min(100.0, max(0.0, baseScore - penalty))

        sessionStats = QuestionStats(
            totalQuestions: total,
            openEndedCount: openEnded,
            closedCount: closed,
            leadingCount: leading,
            doubleBarreledCount: doubleBarreled,
            probingCount: probing,
            openEndedPercentage: openEndedPercentage,
            qualityScore: qualityScore
        )
    }

    /// Update the list of current anti-patterns from the most recent classification
    private func updateCurrentAntiPatterns(from classification: QuestionClassification) {
        // Show anti-patterns from the last few classifications (window of 5)
        let recentClassifications = classifications.suffix(5)
        var patterns: Set<AntiPattern> = []

        for recent in recentClassifications {
            for pattern in recent.antiPatterns {
                patterns.insert(pattern)
            }
        }

        currentAntiPatterns = Array(patterns).sorted { $0.severity > $1.severity }
    }
}
