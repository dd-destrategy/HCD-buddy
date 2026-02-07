//
//  BiasDetector.swift
//  HCD Interview Coach
//
//  Feature D: Cultural Sensitivity & AI Bias Controls
//  Detects systematic bias patterns in interview question sequences
//

import Foundation

// MARK: - Bias Severity

/// Severity level of a detected bias, indicating urgency of correction.
enum BiasSeverity: String, Codable {
    /// Minor concern; pattern is subtle or infrequent
    case low
    /// Moderate concern; pattern may affect data quality
    case medium
    /// Serious concern; pattern likely compromises interview validity
    case high

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }

    /// Color token name for visual severity indicator
    var color: String {
        switch self {
        case .low:
            return "hcdWarning"
        case .medium:
            return "hcdWarning"
        case .high:
            return "hcdError"
        }
    }
}

// MARK: - Bias Type

/// Types of bias that can be detected in interview question patterns.
/// Each type represents a distinct category of interviewer bias that
/// may compromise the validity of research findings.
enum BiasType: String, CaseIterable, Codable {
    /// Questions using gendered language that may exclude or assume
    case genderBias = "gender_bias"
    /// Questions making assumptions based on age or generation
    case ageBias = "age_bias"
    /// Repeated use of confirming language seeking agreement rather than truth
    case confirmationBias = "confirmation_bias"
    /// Systematic overuse of leading questions steering participant responses
    case leadingPatternBias = "leading_pattern"
    /// Excessive reliance on closed questions limiting participant expression
    case closedQuestionOveruse = "closed_overuse"
    /// Language that assumes facts or experiences without verification
    case assumptiveLanguage = "assumptive"

    /// Human-readable name for display in UI
    var displayName: String {
        switch self {
        case .genderBias:
            return "Gender Bias"
        case .ageBias:
            return "Age Bias"
        case .confirmationBias:
            return "Confirmation Bias"
        case .leadingPatternBias:
            return "Leading Pattern"
        case .closedQuestionOveruse:
            return "Closed Question Overuse"
        case .assumptiveLanguage:
            return "Assumptive Language"
        }
    }

    /// Descriptive explanation of the bias type for educational coaching
    var description: String {
        switch self {
        case .genderBias:
            return "Questions contain gendered language that may influence responses or exclude participants."
        case .ageBias:
            return "Questions reference age groups or generational stereotypes that may bias responses."
        case .confirmationBias:
            return "Repeated seeking of agreement rather than open exploration of the participant's perspective."
        case .leadingPatternBias:
            return "A pattern of questions that steer participants toward predetermined answers."
        case .closedQuestionOveruse:
            return "Over 60% of questions are closed, limiting the depth of participant responses."
        case .assumptiveLanguage:
            return "Language assumes facts about the participant's experience without verification."
        }
    }

    /// SF Symbol icon for the bias type
    var icon: String {
        switch self {
        case .genderBias:
            return "person.2.slash"
        case .ageBias:
            return "clock.arrow.circlepath"
        case .confirmationBias:
            return "checkmark.circle.trianglebadge.exclamationmark"
        case .leadingPatternBias:
            return "arrow.right.circle"
        case .closedQuestionOveruse:
            return "lock.circle"
        case .assumptiveLanguage:
            return "quote.opening"
        }
    }

    /// The default severity level for this bias type
    var severity: BiasSeverity {
        switch self {
        case .genderBias:
            return .high
        case .ageBias:
            return .medium
        case .confirmationBias:
            return .high
        case .leadingPatternBias:
            return .medium
        case .closedQuestionOveruse:
            return .low
        case .assumptiveLanguage:
            return .medium
        }
    }
}

// MARK: - Bias Alert

/// A detected bias instance with context and actionable suggestion.
struct BiasAlert: Identifiable, Codable {
    /// Unique identifier for the alert
    let id: UUID
    /// The type of bias detected
    let type: BiasType
    /// Human-readable description of the specific bias instance
    let description: String
    /// IDs of utterances that contributed to this detection
    let utteranceIds: [UUID]
    /// Confidence level of the detection (0.0-1.0)
    let confidence: Double
    /// Actionable suggestion for what to do differently
    let suggestion: String
    /// When the bias was detected
    let detectedAt: Date

    init(
        id: UUID = UUID(),
        type: BiasType,
        description: String,
        utteranceIds: [UUID],
        confidence: Double,
        suggestion: String,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.utteranceIds = utteranceIds
        self.confidence = confidence
        self.suggestion = suggestion
        self.detectedAt = detectedAt
    }
}

// MARK: - Bias Detector

/// Detects systematic bias patterns in interview question sequences.
///
/// Analyzes interviewer questions for various types of bias including
/// gender bias, age bias, confirmation bias, leading patterns,
/// closed question overuse, and assumptive language.
///
/// The detector operates on simple tuples of (utteranceId, text, type)
/// to avoid tight coupling with the QuestionTypeAnalyzer.
@MainActor
final class BiasDetector: ObservableObject {

    // MARK: - Published Properties

    /// All bias alerts detected in the current session
    @Published var alerts: [BiasAlert] = []

    /// Whether the detector is currently analyzing
    @Published var isAnalyzing: Bool = false

    // MARK: - Detection Keywords

    /// Words that may indicate gender bias when used in question framing
    private let genderKeywords: [String] = [
        "he ", "she ", " he ", " she ",
        " guys ", "guys ", " girls ", "girls ",
        " men ", "men ", " women ", "women ",
        " his ", "his ", " her ", " her ",
        " him ", "him ", " himself ", " herself ",
        " man ", " woman ", " boy ", " girl ",
        " boys ", " gentlemen ", " ladies "
    ]

    /// Phrases that may indicate age-based bias
    private let ageKeywords: [String] = [
        "young people", "older users", "old people", "elderly",
        "millennials", "boomers", "gen z", "gen x",
        "your generation", "your age group", "kids these days",
        "back in your day", "at your age", "senior citizens",
        "the younger generation", "the older generation"
    ]

    /// Phrases indicating confirmation-seeking bias
    private let confirmationPhrases: [String] = [
        "right?", "isn't it?", "don't you think?",
        "wouldn't you agree?", "correct?", "isn't that so?",
        "you'd agree that", "surely you", "obviously "
    ]

    /// Phrases indicating assumptive language
    private let assumptivePhrases: [String] = [
        "obviously", "clearly", "of course",
        "everyone knows", "most people",
        "as you know", "naturally",
        "it's clear that", "it's obvious that",
        "without a doubt", "undoubtedly",
        "as we all know", "everybody thinks"
    ]

    // MARK: - Public Methods

    /// Analyze a sequence of question classifications for bias patterns.
    ///
    /// Runs all bias detection algorithms against the provided questions
    /// and populates the `alerts` array with any detected patterns.
    ///
    /// - Parameter classifications: An array of tuples containing
    ///   (utteranceId, question text, question type string)
    func analyze(classifications: [(utteranceId: UUID, text: String, type: String)]) {
        guard !classifications.isEmpty else { return }

        isAnalyzing = true
        var detectedAlerts: [BiasAlert] = []

        let texts = classifications.map { ($0.utteranceId, $0.text) }

        detectedAlerts.append(contentsOf: detectGenderBias(in: texts))
        detectedAlerts.append(contentsOf: detectAgeBias(in: texts))
        detectedAlerts.append(contentsOf: detectConfirmationBias(in: texts))
        detectedAlerts.append(contentsOf: detectLeadingPatternBias(
            classifications: classifications.map { ($0.utteranceId, $0.type) }
        ))
        detectedAlerts.append(contentsOf: detectClosedQuestionOveruse(
            classifications: classifications.map { ($0.utteranceId, $0.type) }
        ))
        detectedAlerts.append(contentsOf: detectAssumptiveLanguage(in: texts))

        alerts = detectedAlerts
        isAnalyzing = false
    }

    /// Remove all detected alerts.
    func clearAlerts() {
        alerts.removeAll()
    }

    // MARK: - Private Detection Methods

    /// Check for gender-biased language in question texts.
    ///
    /// Detects gendered terms used in question framing (not quoting participants).
    /// - Parameter texts: Array of (utterance ID, question text) tuples
    /// - Returns: Array of bias alerts for detected gender bias
    private func detectGenderBias(in texts: [(UUID, String)]) -> [BiasAlert] {
        var matchedIds: [UUID] = []

        for (id, text) in texts {
            let lowercased = " " + text.lowercased() + " "
            for keyword in genderKeywords {
                if lowercased.contains(keyword) {
                    matchedIds.append(id)
                    break
                }
            }
        }

        guard !matchedIds.isEmpty else { return [] }

        return [BiasAlert(
            type: .genderBias,
            description: "Gendered language detected in \(matchedIds.count) question(s). This may unconsciously frame responses around gender assumptions.",
            utteranceIds: matchedIds,
            confidence: min(1.0, Double(matchedIds.count) / Double(texts.count) + 0.5),
            suggestion: "Use gender-neutral language in questions. Replace gendered pronouns with 'they/them' or 'the user/participant' when not quoting."
        )]
    }

    /// Check for age-biased assumptions in question texts.
    ///
    /// Detects references to age groups, generations, or age-based stereotypes.
    /// - Parameter texts: Array of (utterance ID, question text) tuples
    /// - Returns: Array of bias alerts for detected age bias
    private func detectAgeBias(in texts: [(UUID, String)]) -> [BiasAlert] {
        var matchedIds: [UUID] = []

        for (id, text) in texts {
            let lowercased = text.lowercased()
            for keyword in ageKeywords {
                if lowercased.contains(keyword) {
                    matchedIds.append(id)
                    break
                }
            }
        }

        guard !matchedIds.isEmpty else { return [] }

        return [BiasAlert(
            type: .ageBias,
            description: "Age-related assumptions detected in \(matchedIds.count) question(s). Generational references may introduce stereotyping.",
            utteranceIds: matchedIds,
            confidence: min(1.0, Double(matchedIds.count) / Double(texts.count) + 0.4),
            suggestion: "Avoid referencing age groups or generations. Ask about individual experiences rather than generational traits."
        )]
    }

    /// Check for confirmation bias through repeated agreement-seeking patterns.
    ///
    /// Triggers when 3 or more questions contain confirmation-seeking phrases,
    /// indicating a pattern of seeking agreement rather than open exploration.
    /// - Parameter texts: Array of (utterance ID, question text) tuples
    /// - Returns: Array of bias alerts for detected confirmation bias
    private func detectConfirmationBias(in texts: [(UUID, String)]) -> [BiasAlert] {
        var matchedIds: [UUID] = []

        for (id, text) in texts {
            let lowercased = text.lowercased()
            for phrase in confirmationPhrases {
                if lowercased.contains(phrase) {
                    matchedIds.append(id)
                    break
                }
            }
        }

        // Threshold: 3 or more confirmation-seeking questions in a session
        guard matchedIds.count >= 3 else { return [] }

        return [BiasAlert(
            type: .confirmationBias,
            description: "Confirmation-seeking language detected in \(matchedIds.count) question(s). Repeated agreement-seeking may bias participant responses.",
            utteranceIds: matchedIds,
            confidence: min(1.0, Double(matchedIds.count) / Double(texts.count) + 0.3),
            suggestion: "Replace confirmation-seeking phrases with open-ended alternatives. Instead of 'This is better, right?' try 'How does this compare to your previous experience?'"
        )]
    }

    /// Check for a pattern of leading questions in the classification results.
    ///
    /// Triggers when more than 30% of classified questions are identified as leading.
    /// - Parameter classifications: Array of (utterance ID, question type string) tuples
    /// - Returns: Array of bias alerts for detected leading pattern bias
    private func detectLeadingPatternBias(classifications: [(UUID, String)]) -> [BiasAlert] {
        let leadingIds = classifications.filter { $0.1 == "leading" }.map { $0.0 }
        let total = classifications.count

        guard total >= 3 else { return [] }

        let leadingRatio = Double(leadingIds.count) / Double(total)
        guard leadingRatio > 0.3 else { return [] }

        return [BiasAlert(
            type: .leadingPatternBias,
            description: "\(leadingIds.count) of \(total) questions (\(Int(leadingRatio * 100))%) are leading. This systematic pattern may steer participant responses.",
            utteranceIds: leadingIds,
            confidence: min(1.0, leadingRatio + 0.3),
            suggestion: "Rephrase leading questions as neutral, open-ended inquiries. Instead of 'Don't you think X is better?' try 'How do you compare X and Y?'"
        )]
    }

    /// Check for excessive use of closed questions.
    ///
    /// Triggers when more than 60% of questions are closed, which limits
    /// the depth and richness of participant responses.
    /// - Parameter classifications: Array of (utterance ID, question type string) tuples
    /// - Returns: Array of bias alerts for detected closed question overuse
    private func detectClosedQuestionOveruse(classifications: [(UUID, String)]) -> [BiasAlert] {
        let closedIds = classifications.filter { $0.1 == "closed" }.map { $0.0 }
        let total = classifications.count

        guard total >= 3 else { return [] }

        let closedRatio = Double(closedIds.count) / Double(total)
        guard closedRatio > 0.6 else { return [] }

        return [BiasAlert(
            type: .closedQuestionOveruse,
            description: "\(closedIds.count) of \(total) questions (\(Int(closedRatio * 100))%) are closed. This limits the depth of participant responses.",
            utteranceIds: closedIds,
            confidence: min(1.0, closedRatio),
            suggestion: "Balance closed questions with open-ended ones. For every closed question, follow up with 'Tell me more about that' or 'How did that make you feel?'"
        )]
    }

    /// Check for assumptive language in question texts.
    ///
    /// Detects phrases that assume facts or shared knowledge without verification.
    /// - Parameter texts: Array of (utterance ID, question text) tuples
    /// - Returns: Array of bias alerts for detected assumptive language
    private func detectAssumptiveLanguage(in texts: [(UUID, String)]) -> [BiasAlert] {
        var matchedIds: [UUID] = []

        for (id, text) in texts {
            let lowercased = text.lowercased()
            for phrase in assumptivePhrases {
                if lowercased.contains(phrase) {
                    matchedIds.append(id)
                    break
                }
            }
        }

        guard !matchedIds.isEmpty else { return [] }

        return [BiasAlert(
            type: .assumptiveLanguage,
            description: "Assumptive language detected in \(matchedIds.count) question(s). Words like 'obviously' or 'everyone knows' presume shared understanding.",
            utteranceIds: matchedIds,
            confidence: min(1.0, Double(matchedIds.count) / Double(texts.count) + 0.4),
            suggestion: "Remove assumptive qualifiers from questions. Instead of 'Obviously this is frustrating, how do you cope?' try 'Can you describe your experience with this?'"
        )]
    }
}
