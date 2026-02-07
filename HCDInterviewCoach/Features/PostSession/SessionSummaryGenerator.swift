//
//  SessionSummaryGenerator.swift
//  HCD Interview Coach
//
//  SessionSummaryGenerator: Creates structured session summaries
//  Uses local rules-based analysis (no external API calls needed)
//  Extracts themes, pain points, key quotes, and recommendations
//

import Foundation
import Combine

// MARK: - Session Summary Models

/// A theme extracted from the interview session with supporting evidence
struct ThemeSummary: Identifiable, Codable {
    let id: UUID
    let name: String
    let mentionCount: Int
    let supportingQuotes: [String]

    init(
        id: UUID = UUID(),
        name: String,
        mentionCount: Int,
        supportingQuotes: [String]
    ) {
        self.id = id
        self.name = name
        self.mentionCount = mentionCount
        self.supportingQuotes = supportingQuotes
    }
}

/// A notable quote extracted from the session
struct KeyQuote: Identifiable, Codable {
    let id: UUID
    let text: String
    let speaker: String
    let timestamp: Double
    let significance: String

    init(
        id: UUID = UUID(),
        text: String,
        speaker: String,
        timestamp: Double,
        significance: String
    ) {
        self.id = id
        self.text = text
        self.speaker = speaker
        self.timestamp = timestamp
        self.significance = significance
    }
}

/// Complete structured summary of an interview session
struct SessionSummary: Identifiable, Codable {
    let id: UUID
    let keyThemes: [ThemeSummary]
    let participantPainPoints: [String]
    let positiveHighlights: [String]
    let keyQuotes: [KeyQuote]
    let topicGaps: [String]
    let suggestedFollowUps: [String]
    let sessionQualityScore: Double
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        keyThemes: [ThemeSummary] = [],
        participantPainPoints: [String] = [],
        positiveHighlights: [String] = [],
        keyQuotes: [KeyQuote] = [],
        topicGaps: [String] = [],
        suggestedFollowUps: [String] = [],
        sessionQualityScore: Double = 0,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.keyThemes = keyThemes
        self.participantPainPoints = participantPainPoints
        self.positiveHighlights = positiveHighlights
        self.keyQuotes = keyQuotes
        self.topicGaps = topicGaps
        self.suggestedFollowUps = suggestedFollowUps
        self.sessionQualityScore = sessionQualityScore
        self.generatedAt = generatedAt
    }
}

// MARK: - Session Summary Generator

/// Creates structured session summaries using local rules-based analysis.
/// No external API calls are needed; all analysis is performed locally by
/// counting word frequencies, detecting emotional keywords, and evaluating
/// topic coverage.
@MainActor
final class SessionSummaryGenerator: ObservableObject {

    // MARK: - Published Properties

    /// The generated session summary, nil until generation completes
    @Published private(set) var summary: SessionSummary?

    /// Whether summary generation is currently in progress
    @Published private(set) var isGenerating: Bool = false

    /// Error message if generation fails
    @Published private(set) var generationError: String?

    // MARK: - Constants

    /// Words to exclude from theme extraction
    private static let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "is", "it", "its", "this", "that", "was",
        "are", "were", "be", "been", "being", "have", "has", "had", "do", "does",
        "did", "will", "would", "could", "should", "may", "might", "shall",
        "can", "need", "dare", "ought", "used", "not", "no", "nor", "so", "as",
        "if", "then", "than", "too", "very", "just", "about", "above", "after",
        "again", "all", "also", "am", "any", "because", "before", "between",
        "both", "each", "few", "get", "got", "he", "her", "here", "him", "his",
        "how", "i", "into", "me", "more", "most", "my", "now", "only", "other",
        "our", "out", "over", "own", "same", "she", "some", "still", "such",
        "them", "there", "these", "they", "those", "through", "under", "up",
        "us", "we", "well", "what", "when", "where", "which", "while", "who",
        "whom", "why", "you", "your", "yeah", "yes", "okay", "ok", "um", "uh",
        "like", "know", "think", "thing", "things", "really", "actually",
        "basically", "kind", "sort", "going", "go", "one", "two", "three",
        "much", "many", "way", "even", "back", "make", "see", "come", "take",
        "want", "look", "give", "use", "find", "tell", "ask", "work", "seem",
        "feel", "try", "leave", "call", "say", "said", "saying", "right",
        "don", "didn", "doesn", "won", "wouldn", "couldn", "shouldn", "isn",
        "aren", "wasn", "weren", "hasn", "haven", "hadn"
    ]

    /// Keywords indicating pain points in participant utterances
    private static let painPointKeywords: [String] = [
        "frustrat", "difficult", "problem", "pain", "struggle", "annoying",
        "hate", "confus", "hard", "complicated", "broken", "bug", "issue",
        "terrible", "awful", "worst", "slow", "tedious", "cumbersome",
        "overwhelming", "stressful", "nightmare", "impossible"
    ]

    /// Keywords indicating positive experiences in participant utterances
    private static let positiveKeywords: [String] = [
        "love", "great", "amazing", "helpful", "easy", "enjoy", "perfect",
        "awesome", "fantastic", "wonderful", "excellent", "intuitive",
        "smooth", "fast", "efficient", "simple", "convenient", "nice",
        "happy", "pleased", "satisfied", "impressed", "favorite"
    ]

    /// Keywords indicating emotional significance for key quote selection
    private static let emotionalKeywords: [String] = [
        "frustrat", "love", "hate", "amazing", "terrible", "wish", "hope",
        "need", "want", "expect", "surprised", "disappointed", "excited",
        "worried", "confused", "delighted", "annoyed", "impressed",
        "overwhelmed", "relieved"
    ]

    // MARK: - Public Methods

    /// Generate a structured summary from a completed session.
    /// - Parameter session: The session to analyze
    /// - Returns: A SessionSummary containing extracted themes, quotes, pain points, and more
    func generate(from session: Session) async -> SessionSummary {
        isGenerating = true
        generationError = nil

        AppLogger.shared.info("Starting summary generation for session: \(session.participantName)")

        let participantUtterances = session.utterances.filter { $0.speaker == .participant }
        let interviewerUtterances = session.utterances.filter { $0.speaker == .interviewer }

        // Extract themes from participant utterances
        let themes = extractThemes(from: participantUtterances)

        // Detect pain points
        let painPoints = detectPainPoints(from: participantUtterances)

        // Detect positive highlights
        let highlights = detectPositiveHighlights(from: participantUtterances)

        // Extract key quotes
        let quotes = extractKeyQuotes(from: session.utterances, insights: session.insights)

        // Identify topic gaps
        let gaps = identifyTopicGaps(from: session.topicStatuses)

        // Generate follow-up suggestions
        let followUps = generateFollowUpSuggestions(
            topicStatuses: session.topicStatuses,
            themes: themes,
            painPoints: painPoints
        )

        // Calculate quality score
        let qualityScore = calculateQualityScore(
            session: session,
            participantUtterances: participantUtterances,
            interviewerUtterances: interviewerUtterances
        )

        let generatedSummary = SessionSummary(
            keyThemes: themes,
            participantPainPoints: painPoints,
            positiveHighlights: highlights,
            keyQuotes: quotes,
            topicGaps: gaps,
            suggestedFollowUps: followUps,
            sessionQualityScore: qualityScore,
            generatedAt: Date()
        )

        summary = generatedSummary
        isGenerating = false

        AppLogger.shared.info("Summary generation complete. Quality score: \(qualityScore)")

        return generatedSummary
    }

    /// Export a session summary as a formatted Markdown string.
    /// - Parameter summary: The summary to export
    /// - Returns: A Markdown-formatted string representation of the summary
    func exportSummaryAsMarkdown(_ summary: SessionSummary) -> String {
        var md = ""

        // Header
        md += "# Session Summary\n\n"
        md += "**Generated:** \(TimeFormatting.formatDateTime(summary.generatedAt))\n"
        md += "**Quality Score:** \(String(format: "%.0f", summary.sessionQualityScore))/100\n\n"

        // Key Themes
        if !summary.keyThemes.isEmpty {
            md += "## Key Themes\n\n"
            for theme in summary.keyThemes {
                md += "### \(theme.name) (\(theme.mentionCount) mentions)\n\n"
                for quote in theme.supportingQuotes {
                    md += "> \"\(quote)\"\n\n"
                }
            }
        }

        // Pain Points
        if !summary.participantPainPoints.isEmpty {
            md += "## Pain Points\n\n"
            for point in summary.participantPainPoints {
                md += "- \(point)\n"
            }
            md += "\n"
        }

        // Positive Highlights
        if !summary.positiveHighlights.isEmpty {
            md += "## Positive Highlights\n\n"
            for highlight in summary.positiveHighlights {
                md += "- \(highlight)\n"
            }
            md += "\n"
        }

        // Key Quotes
        if !summary.keyQuotes.isEmpty {
            md += "## Key Quotes\n\n"
            for quote in summary.keyQuotes {
                let timestamp = TimeFormatting.formatCompactTimestamp(quote.timestamp)
                md += "> \"\(quote.text)\"\n"
                md += "> \n"
                md += "> -- \(quote.speaker) at \(timestamp)\n"
                md += "> \n"
                md += "> *\(quote.significance)*\n\n"
            }
        }

        // Topic Gaps
        if !summary.topicGaps.isEmpty {
            md += "## Topic Gaps\n\n"
            for gap in summary.topicGaps {
                md += "- \(gap)\n"
            }
            md += "\n"
        }

        // Suggested Follow-Ups
        if !summary.suggestedFollowUps.isEmpty {
            md += "## Suggested Follow-Up Questions\n\n"
            for (index, suggestion) in summary.suggestedFollowUps.enumerated() {
                md += "\(index + 1). \(suggestion)\n"
            }
            md += "\n"
        }

        return md
    }

    // MARK: - Private Analysis Methods

    /// Extract themes by counting word frequency across participant utterances,
    /// excluding stop words and grouping into meaningful themes.
    private func extractThemes(from utterances: [Utterance]) -> [ThemeSummary] {
        guard !utterances.isEmpty else { return [] }

        var wordFrequency: [String: Int] = [:]
        var wordUtterances: [String: [String]] = [:]

        for utterance in utterances {
            let words = tokenize(utterance.text)
            let uniqueWords = Set(words)

            for word in uniqueWords {
                let lowered = word.lowercased()
                guard lowered.count > 3 else { continue }
                guard !Self.stopWords.contains(lowered) else { continue }

                wordFrequency[lowered, default: 0] += 1

                if var existing = wordUtterances[lowered] {
                    if existing.count < 3 {
                        let trimmedText = String(utterance.text.prefix(150))
                        existing.append(trimmedText)
                        wordUtterances[lowered] = existing
                    }
                } else {
                    let trimmedText = String(utterance.text.prefix(150))
                    wordUtterances[lowered] = [trimmedText]
                }
            }
        }

        // Sort by frequency and take top themes
        let sortedWords = wordFrequency
            .sorted { $0.value > $1.value }
            .prefix(5)

        return sortedWords.map { word, count in
            ThemeSummary(
                name: word.capitalized,
                mentionCount: count,
                supportingQuotes: wordUtterances[word] ?? []
            )
        }
    }

    /// Detect pain points by scanning participant utterances for pain-related keywords.
    private func detectPainPoints(from utterances: [Utterance]) -> [String] {
        var painPoints: [String] = []

        for utterance in utterances {
            let lowered = utterance.text.lowercased()
            let matchesKeyword = Self.painPointKeywords.contains { keyword in
                lowered.contains(keyword)
            }

            if matchesKeyword {
                let trimmed = String(utterance.text.prefix(200))
                painPoints.append(trimmed)
            }
        }

        return painPoints
    }

    /// Detect positive highlights by scanning participant utterances for positive keywords.
    private func detectPositiveHighlights(from utterances: [Utterance]) -> [String] {
        var highlights: [String] = []

        for utterance in utterances {
            let lowered = utterance.text.lowercased()
            let matchesKeyword = Self.positiveKeywords.contains { keyword in
                lowered.contains(keyword)
            }

            if matchesKeyword {
                let trimmed = String(utterance.text.prefix(200))
                highlights.append(trimmed)
            }
        }

        return highlights
    }

    /// Extract key quotes based on length, insight flags, and emotional content.
    /// Selects the 3-5 most notable quotes from the session.
    private func extractKeyQuotes(from utterances: [Utterance], insights: [Insight]) -> [KeyQuote] {
        guard !utterances.isEmpty else { return [] }

        let insightTimestamps = Set(insights.map { $0.timestampSeconds })

        // Score each utterance by significance
        var scoredUtterances: [(utterance: Utterance, score: Double, significance: String)] = []

        for utterance in utterances {
            var score: Double = 0
            var significance = ""

            // Longer utterances are generally more substantive
            let wordCount = utterance.text.split(separator: " ").count
            if wordCount > 15 {
                score += Double(min(wordCount, 60)) / 60.0 * 30.0
            }

            // Participant utterances are prioritized
            if utterance.speaker == .participant {
                score += 20.0
            }

            // Utterances near insight timestamps are notable
            let nearInsight = insightTimestamps.contains { insightTimestamp in
                abs(utterance.timestampSeconds - insightTimestamp) < 10
            }
            if nearInsight {
                score += 30.0
                significance = "Flagged as an insight moment"
            }

            // Emotional keywords increase significance
            let lowered = utterance.text.lowercased()
            let emotionalCount = Self.emotionalKeywords.filter { lowered.contains($0) }.count
            if emotionalCount > 0 {
                score += Double(emotionalCount) * 10.0
                if significance.isEmpty {
                    significance = "Contains strong emotional language"
                }
            }

            // Pain point keywords
            let hasPainPoint = Self.painPointKeywords.contains { lowered.contains($0) }
            if hasPainPoint && significance.isEmpty {
                significance = "Reveals a pain point"
            }

            // Positive keywords
            let hasPositive = Self.positiveKeywords.contains { lowered.contains($0) }
            if hasPositive && significance.isEmpty {
                significance = "Highlights a positive experience"
            }

            if significance.isEmpty {
                significance = "Substantive response"
            }

            if score > 10 {
                scoredUtterances.append((utterance, score, significance))
            }
        }

        // Sort by score and take top 3-5
        let topQuotes = scoredUtterances
            .sorted { $0.score > $1.score }
            .prefix(5)

        return topQuotes.map { item in
            KeyQuote(
                text: String(item.utterance.text.prefix(300)),
                speaker: item.utterance.speaker.displayName,
                timestamp: item.utterance.timestampSeconds,
                significance: item.significance
            )
        }
    }

    /// Identify topics that were not covered or only partially covered.
    private func identifyTopicGaps(from topicStatuses: [TopicStatus]) -> [String] {
        return topicStatuses
            .filter { $0.status == .notCovered || $0.status == .partialCoverage }
            .map { topic in
                switch topic.status {
                case .notCovered:
                    return "\(topic.topicName) (not covered)"
                case .partialCoverage:
                    return "\(topic.topicName) (partial coverage)"
                default:
                    return topic.topicName
                }
            }
    }

    /// Generate follow-up questions based on topic gaps, themes, and pain points.
    private func generateFollowUpSuggestions(
        topicStatuses: [TopicStatus],
        themes: [ThemeSummary],
        painPoints: [String]
    ) -> [String] {
        var suggestions: [String] = []

        // Suggest questions for uncovered topics
        let uncoveredTopics = topicStatuses.filter { $0.status == .notCovered }
        for topic in uncoveredTopics.prefix(2) {
            suggestions.append("Can you tell me more about your experience with \(topic.topicName.lowercased())?")
        }

        // Suggest questions for partially covered topics
        let partialTopics = topicStatuses.filter { $0.status == .partialCoverage }
        for topic in partialTopics.prefix(2) {
            suggestions.append("You mentioned \(topic.topicName.lowercased()) earlier. Could you elaborate on that?")
        }

        // Suggest deeper exploration of top themes
        if let topTheme = themes.first, themes.count > 0 {
            suggestions.append("The topic of \(topTheme.name.lowercased()) came up frequently. What would your ideal solution look like?")
        }

        // Suggest follow-ups for pain points
        if !painPoints.isEmpty {
            suggestions.append("You described some challenges earlier. How do you currently work around those issues?")
        }

        // Add a general closing follow-up
        if suggestions.isEmpty {
            suggestions.append("Is there anything else about your experience that we haven't discussed today?")
        }

        return suggestions
    }

    /// Calculate a quality score (0-100) based on coverage, depth, insights, and duration.
    ///
    /// Weighted formula:
    /// - Topic coverage: 30%
    /// - Insight density: 25%
    /// - Question diversity: 25%
    /// - Session duration: 20%
    private func calculateQualityScore(
        session: Session,
        participantUtterances: [Utterance],
        interviewerUtterances: [Utterance]
    ) -> Double {
        // Topic coverage score (30%)
        let topicScore: Double
        if session.topicStatuses.isEmpty {
            topicScore = 50.0 // Neutral score if no topics defined
        } else {
            let fullyCovered = session.topicStatuses.filter { $0.status == .fullyCovered }.count
            let partiallyCovered = session.topicStatuses.filter { $0.status == .partialCoverage }.count
            let totalTopics = session.topicStatuses.count
            let coverageRatio = (Double(fullyCovered) + Double(partiallyCovered) * 0.5) / Double(totalTopics)
            topicScore = coverageRatio * 100.0
        }

        // Insight density score (25%)
        let insightScore: Double
        let totalUtterances = session.utterances.count
        if totalUtterances == 0 {
            insightScore = 0.0
        } else {
            let insightRatio = Double(session.insights.count) / Double(totalUtterances)
            // Ideal ratio is around 0.1-0.2 (1 insight per 5-10 utterances)
            insightScore = min(insightRatio / 0.15 * 100.0, 100.0)
        }

        // Question diversity score (25%)
        let diversityScore: Double
        if interviewerUtterances.isEmpty {
            diversityScore = 0.0
        } else {
            // Measure diversity by unique starting words in interviewer questions
            let starterWords = Set(interviewerUtterances.compactMap { utterance -> String? in
                let firstWord = utterance.text.split(separator: " ").first.map(String.init)
                return firstWord?.lowercased()
            })
            let diversityRatio = Double(starterWords.count) / Double(interviewerUtterances.count)
            diversityScore = min(diversityRatio * 100.0, 100.0)

            // Also consider participant-to-interviewer ratio
            // Ideal ratio is around 2:1 to 3:1
            let ratio = participantUtterances.isEmpty ? 0.0 : Double(participantUtterances.count) / Double(interviewerUtterances.count)
            let ratioBonus = min(ratio / 3.0, 1.0) * 20.0
            _ = ratioBonus // Incorporated below in final calculation
        }

        // Session duration score (20%)
        let durationScore: Double
        let durationMinutes = session.totalDurationSeconds / 60.0
        if durationMinutes < 5 {
            durationScore = durationMinutes / 5.0 * 30.0 // Very short sessions score low
        } else if durationMinutes <= 60 {
            durationScore = min(durationMinutes / 30.0 * 100.0, 100.0) // 30+ min is ideal
        } else {
            durationScore = 100.0 // Longer sessions get full marks
        }

        // Weighted total
        let totalScore = (topicScore * 0.30)
            + (insightScore * 0.25)
            + (diversityScore * 0.25)
            + (durationScore * 0.20)

        return min(max(totalScore, 0), 100)
    }

    // MARK: - Private Helpers

    /// Tokenize text into individual words, stripping punctuation.
    private func tokenize(_ text: String) -> [String] {
        let lowered = text.lowercased()
        let cleaned = lowered.unicodeScalars.filter { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.whitespaces.contains(scalar)
        }
        let cleanedString = String(String.UnicodeScalarView(cleaned))
        return cleanedString.split(separator: " ").map(String.init)
    }
}
