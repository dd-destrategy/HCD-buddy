//
//  TopicAnalyzer.swift
//  HCD Interview Coach
//
//  EPIC E7: Topic Awareness
//  AI-driven topic detection and coverage analysis
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - Topic Analyzer

/// Analyzes conversation transcript to detect topic coverage and update status.
/// Uses NLP techniques combined with keyword matching for accurate detection.
///
/// Detection Strategy:
/// 1. Keyword/phrase matching for explicit mentions
/// 2. Semantic similarity using NLEmbedding for related concepts
/// 3. Conversation depth analysis (follow-up questions, elaboration)
/// 4. Speaker pattern analysis (interviewer probing vs participant explanation)
@MainActor
final class TopicAnalyzer: ObservableObject {

    // MARK: - Published State

    /// Current topic coverage results
    @Published private(set) var topicCoverages: [String: TopicCoverage] = [:]

    /// Whether analysis is currently running
    @Published private(set) var isAnalyzing: Bool = false

    /// Last analysis timestamp
    @Published private(set) var lastAnalyzedAt: Date?

    /// Error from last analysis attempt
    @Published private(set) var lastError: TopicAnalysisError?

    // MARK: - Configuration

    /// Minimum confidence threshold for topic detection (0.0 - 1.0)
    var confidenceThreshold: Double = 0.4

    /// Enable semantic similarity matching
    var useSemanticMatching: Bool = true

    /// Minimum word count for depth analysis
    var minimumDepthWordCount: Int = 50

    // MARK: - Private Properties

    private var topics: [String] = []
    private var topicKeywords: [String: [String]] = [:]
    private var embedding: NLEmbedding?
    private var analysisTask: Task<Void, Never>?
    private var utteranceBuffer: [AnalyzedUtterance] = []

    // MARK: - Initialization

    init() {
        loadEmbedding()
    }

    deinit {
        analysisTask?.cancel()
    }

    // MARK: - Configuration

    /// Configures the analyzer with research topics
    /// - Parameters:
    ///   - topics: List of research topic names
    ///   - keywords: Optional dictionary mapping topics to related keywords
    func configure(topics: [String], keywords: [String: [String]]? = nil) {
        self.topics = topics
        self.topicKeywords = keywords ?? generateDefaultKeywords(for: topics)

        // Initialize coverage tracking
        for topic in topics {
            topicCoverages[topic] = TopicCoverage(
                topicName: topic,
                status: .notStarted,
                mentionCount: 0,
                confidence: 0.0,
                lastMentionedAt: nil,
                relatedUtterances: []
            )
        }

        lastError = nil
    }

    /// Resets the analyzer state
    func reset() {
        topicCoverages.removeAll()
        utteranceBuffer.removeAll()
        lastAnalyzedAt = nil
        lastError = nil
        analysisTask?.cancel()
        isAnalyzing = false
    }

    // MARK: - Analysis

    /// Analyzes a new utterance for topic coverage
    /// - Parameters:
    ///   - text: The utterance text
    ///   - speaker: The speaker who made the utterance
    ///   - timestamp: Timestamp of the utterance
    func analyze(text: String, speaker: Speaker, timestamp: TimeInterval) {
        guard !text.isEmpty else { return }

        let utterance = AnalyzedUtterance(
            text: text,
            speaker: speaker,
            timestamp: timestamp,
            wordCount: text.split(separator: " ").count
        )

        utteranceBuffer.append(utterance)

        // Perform incremental analysis
        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            await self?.performIncrementalAnalysis(utterance)
        }
    }

    /// Performs full re-analysis of all utterances
    func reanalyzeAll() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        // Reset coverage tracking
        for topic in topics {
            topicCoverages[topic] = TopicCoverage(
                topicName: topic,
                status: .notStarted,
                mentionCount: 0,
                confidence: 0.0,
                lastMentionedAt: nil,
                relatedUtterances: []
            )
        }

        // Analyze all buffered utterances
        for utterance in utteranceBuffer {
            await performIncrementalAnalysis(utterance)
        }

        lastAnalyzedAt = Date()
    }

    // MARK: - Manual Override

    /// Manually sets the coverage status for a topic
    /// - Parameters:
    ///   - topic: The topic name
    ///   - status: The new coverage status
    func setStatus(for topic: String, to status: TopicCoverageStatus) {
        guard var coverage = topicCoverages[topic] else { return }

        coverage.status = status
        coverage.isManualOverride = true
        coverage.lastUpdatedAt = Date()

        topicCoverages[topic] = coverage
    }

    /// Cycles the coverage status for a topic to the next level
    /// - Parameter topic: The topic name
    /// - Returns: The new status
    @discardableResult
    func cycleStatus(for topic: String) -> TopicCoverageStatus? {
        guard var coverage = topicCoverages[topic] else { return nil }

        coverage.status = coverage.status.next
        coverage.isManualOverride = true
        coverage.lastUpdatedAt = Date()

        topicCoverages[topic] = coverage
        return coverage.status
    }

    // MARK: - Query Methods

    /// Returns topics that have not been started
    var uncoveredTopics: [String] {
        topicCoverages.filter { $0.value.status == .notStarted }.map { $0.key }
    }

    /// Returns topics that are in progress (mentioned or explored)
    var inProgressTopics: [String] {
        topicCoverages.filter { $0.value.status == .mentioned || $0.value.status == .explored }.map { $0.key }
    }

    /// Returns topics that have been fully covered
    var completedTopics: [String] {
        topicCoverages.filter { $0.value.status == .deepDive }.map { $0.key }
    }

    /// Overall coverage percentage across all topics
    var overallCoverage: Double {
        guard !topicCoverages.isEmpty else { return 0.0 }

        let totalProgress = topicCoverages.values.reduce(0.0) { $0 + $1.status.progressValue }
        return totalProgress / Double(topicCoverages.count)
    }

    // MARK: - Private Methods

    private func loadEmbedding() {
        if useSemanticMatching {
            embedding = NLEmbedding.wordEmbedding(for: .english)
        }
    }

    private func generateDefaultKeywords(for topics: [String]) -> [String: [String]] {
        var keywords: [String: [String]] = [:]

        for topic in topics {
            // Generate keywords from topic name
            let words = topic.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 }

            keywords[topic] = words
        }

        return keywords
    }

    private func performIncrementalAnalysis(_ utterance: AnalyzedUtterance) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let normalizedText = utterance.text.lowercased()

        for topic in topics {
            guard var coverage = topicCoverages[topic] else { continue }

            // Skip if manually overridden
            if coverage.isManualOverride { continue }

            // Perform detection
            let detection = detectTopic(topic, in: normalizedText, utterance: utterance)

            if detection.isDetected {
                coverage.mentionCount += 1
                coverage.confidence = max(coverage.confidence, detection.confidence)
                coverage.lastMentionedAt = Date()
                coverage.relatedUtterances.append(utterance.text)

                // Limit stored utterances
                if coverage.relatedUtterances.count > 10 {
                    coverage.relatedUtterances.removeFirst()
                }

                // Update status based on depth
                coverage.status = calculateStatus(for: coverage, detection: detection)
                coverage.lastUpdatedAt = Date()

                topicCoverages[topic] = coverage
            }
        }

        lastAnalyzedAt = Date()
    }

    private func detectTopic(_ topic: String, in text: String, utterance: AnalyzedUtterance) -> TopicDetection {
        var isDetected = false
        var confidence: Double = 0.0
        var matchType: TopicMatchType = .none

        // 1. Direct keyword matching
        let keywords = topicKeywords[topic] ?? []
        for keyword in keywords {
            if text.contains(keyword.lowercased()) {
                isDetected = true
                confidence = max(confidence, 0.8)
                matchType = .keyword
            }
        }

        // 2. Topic name matching
        let topicWords = topic.lowercased().components(separatedBy: " ")
        for word in topicWords where word.count > 2 {
            if text.contains(word) {
                isDetected = true
                confidence = max(confidence, 0.7)
                if matchType == .none {
                    matchType = .topicName
                }
            }
        }

        // 3. Semantic similarity (if enabled)
        if useSemanticMatching, let embedding = embedding, !isDetected {
            let semanticScore = calculateSemanticSimilarity(topic: topic, text: text, embedding: embedding)
            if semanticScore > confidenceThreshold {
                isDetected = true
                confidence = max(confidence, semanticScore)
                matchType = .semantic
            }
        }

        // Determine depth level
        let hasFollowUp = detectFollowUpPattern(in: text, speaker: utterance.speaker)
        let hasDetail = utterance.wordCount >= minimumDepthWordCount
        let depthLevel = calculateDepthLevel(hasFollowUp: hasFollowUp, hasDetail: hasDetail)

        return TopicDetection(
            isDetected: isDetected,
            confidence: confidence,
            matchType: matchType,
            depthLevel: depthLevel
        )
    }

    private func calculateSemanticSimilarity(topic: String, text: String, embedding: NLEmbedding) -> Double {
        let topicWords = topic.lowercased().components(separatedBy: " ")
        let textWords = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }

        var maxSimilarity: Double = 0.0

        for topicWord in topicWords {
            for textWord in textWords {
                if let distance = embedding.distance(between: topicWord, and: textWord.lowercased()) {
                    // Convert distance to similarity (distance of 0 = similarity of 1)
                    let similarity = max(0, 1.0 - distance)
                    maxSimilarity = max(maxSimilarity, similarity)
                }
            }
        }

        return maxSimilarity
    }

    private func detectFollowUpPattern(in text: String, speaker: Speaker) -> Bool {
        // Follow-up indicators from interviewer
        let followUpPhrases = [
            "tell me more",
            "can you elaborate",
            "what do you mean",
            "could you explain",
            "how does that",
            "why do you",
            "what happens when",
            "can you give me an example",
            "walk me through"
        ]

        if speaker == .interviewer {
            return followUpPhrases.contains { text.lowercased().contains($0) }
        }

        // Detail indicators from participant
        let detailPhrases = [
            "for example",
            "specifically",
            "in particular",
            "what i mean is",
            "let me explain",
            "the reason is",
            "because"
        ]

        return detailPhrases.contains { text.lowercased().contains($0) }
    }

    private func calculateDepthLevel(hasFollowUp: Bool, hasDetail: Bool) -> Int {
        if hasFollowUp && hasDetail {
            return 3
        } else if hasFollowUp || hasDetail {
            return 2
        } else {
            return 1
        }
    }

    private func calculateStatus(for coverage: TopicCoverage, detection: TopicDetection) -> TopicCoverageStatus {
        // Consider mention count and depth
        let mentionScore = min(Double(coverage.mentionCount) / 5.0, 1.0)
        let depthScore = Double(detection.depthLevel) / 3.0
        let confidenceScore = coverage.confidence

        let overallScore = (mentionScore * 0.3) + (depthScore * 0.5) + (confidenceScore * 0.2)

        return TopicCoverageStatus.from(coverageScore: overallScore)
    }
}

// MARK: - Supporting Types

/// Represents the current coverage state of a topic
struct TopicCoverage {
    var topicName: String
    var status: TopicCoverageStatus
    var mentionCount: Int
    var confidence: Double
    var lastMentionedAt: Date?
    var lastUpdatedAt: Date?
    var relatedUtterances: [String]
    var isManualOverride: Bool = false
}

/// An analyzed utterance with metadata
struct AnalyzedUtterance {
    let text: String
    let speaker: Speaker
    let timestamp: TimeInterval
    let wordCount: Int
}

/// Result of topic detection
struct TopicDetection {
    let isDetected: Bool
    let confidence: Double
    let matchType: TopicMatchType
    let depthLevel: Int
}

/// Type of match that detected the topic
enum TopicMatchType {
    case none
    case keyword
    case topicName
    case semantic
}

/// Errors that can occur during topic analysis
enum TopicAnalysisError: LocalizedError {
    case noTopicsConfigured
    case analysisInterrupted
    case embeddingUnavailable

    var errorDescription: String? {
        switch self {
        case .noTopicsConfigured:
            return "No research topics have been configured for analysis"
        case .analysisInterrupted:
            return "Topic analysis was interrupted"
        case .embeddingUnavailable:
            return "Semantic analysis is unavailable"
        }
    }
}
