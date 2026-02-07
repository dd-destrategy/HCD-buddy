//
//  SentimentAnalyzer.swift
//  HCD Interview Coach
//
//  Feature G: Emotional Arc Tracking
//  Rules-based sentiment analysis service that scores utterances for
//  polarity, intensity, and dominant emotion without external dependencies.
//

import Foundation

// MARK: - Sentiment Polarity

/// Sentiment polarity classification for an utterance
enum SentimentPolarity: String, Codable, CaseIterable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case mixed = "mixed"

    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        case .mixed: return "Mixed"
        }
    }

    /// SF Symbol representing this polarity
    var icon: String {
        switch self {
        case .positive: return "face.smiling"
        case .neutral: return "face.dashed"
        case .negative: return "face.smiling.inverse"
        case .mixed: return "arrow.left.arrow.right"
        }
    }

    /// The semantic color token name for this polarity
    var colorName: String {
        switch self {
        case .positive: return "hcdSuccess"
        case .neutral: return "hcdTextSecondary"
        case .negative: return "hcdError"
        case .mixed: return "hcdWarning"
        }
    }
}

// MARK: - Sentiment Result

/// Sentiment analysis result for a single utterance
struct SentimentResult: Identifiable, Codable, Equatable {
    let id: UUID
    let utteranceId: UUID
    let polarity: SentimentPolarity
    let score: Double        // -1.0 (very negative) to +1.0 (very positive)
    let intensity: Double    // 0.0 (neutral) to 1.0 (very intense)
    let dominantEmotion: String?  // e.g., "frustration", "delight", "confusion"
    let timestamp: Double    // From utterance timestampSeconds

    init(
        id: UUID = UUID(),
        utteranceId: UUID,
        polarity: SentimentPolarity,
        score: Double,
        intensity: Double,
        dominantEmotion: String?,
        timestamp: Double
    ) {
        self.id = id
        self.utteranceId = utteranceId
        self.polarity = polarity
        self.score = score
        self.intensity = intensity
        self.dominantEmotion = dominantEmotion
        self.timestamp = timestamp
    }

    static func == (lhs: SentimentResult, rhs: SentimentResult) -> Bool {
        lhs.id == rhs.id
            && lhs.utteranceId == rhs.utteranceId
            && lhs.polarity == rhs.polarity
            && lhs.score == rhs.score
            && lhs.intensity == rhs.intensity
            && lhs.dominantEmotion == rhs.dominantEmotion
            && lhs.timestamp == rhs.timestamp
    }
}

// MARK: - Emotional Shift

/// A significant emotional shift between consecutive utterances
struct EmotionalShift: Identifiable, Codable {
    let id: UUID
    let fromResult: SentimentResult
    let toResult: SentimentResult
    let shiftMagnitude: Double  // Absolute change in score
    let description: String     // e.g., "Positive -> Negative (frustration)"

    init(
        id: UUID = UUID(),
        fromResult: SentimentResult,
        toResult: SentimentResult,
        shiftMagnitude: Double,
        description: String
    ) {
        self.id = id
        self.fromResult = fromResult
        self.toResult = toResult
        self.shiftMagnitude = shiftMagnitude
        self.description = description
    }
}

// MARK: - Emotional Arc Summary

/// Emotional arc summary for a session, providing aggregate sentiment metrics
struct EmotionalArcSummary: Codable {
    let averageSentiment: Double
    let minSentiment: Double
    let maxSentiment: Double
    let emotionalShifts: [EmotionalShift]
    let dominantPolarity: SentimentPolarity
    let intensityPeaks: [SentimentResult]  // Top 3 most intense moments
    let arcDescription: String  // e.g., "Started positive, dipped negative mid-session, recovered"

    /// Convenience accessor for sentiment range
    var sentimentRange: (min: Double, max: Double) {
        (min: minSentiment, max: maxSentiment)
    }
}

// MARK: - Sentiment Analyzer

/// Rules-based sentiment analysis service that scores utterances for polarity,
/// intensity, and dominant emotion without external ML dependencies.
///
/// The scoring algorithm:
/// 1. Tokenizes text into lowercase words
/// 2. Checks each word against positive/negative lexicons for a base score
/// 3. Applies negator inversion (within 3 words) to flip polarity
/// 4. Applies intensifier multiplication (within 2 words) at 1.5x
/// 5. Weights the final clause of each sentence by 1.3x (recency effect)
/// 6. Aggregates the average of all scored words into a final score
/// 7. Classifies polarity based on score thresholds
@MainActor
final class SentimentAnalyzer: ObservableObject {

    // MARK: - Published Properties

    @Published var results: [SentimentResult] = []
    @Published var emotionalShifts: [EmotionalShift] = []
    @Published var arcSummary: EmotionalArcSummary?

    // MARK: - Positive Lexicon (~55 words)

    static let positiveWords: [String: Double] = [
        "love": 0.9, "great": 0.7, "amazing": 0.9, "perfect": 0.85, "helpful": 0.6,
        "enjoy": 0.7, "easy": 0.5, "awesome": 0.8, "fantastic": 0.85, "wonderful": 0.8,
        "excellent": 0.85, "intuitive": 0.6, "smooth": 0.5, "fast": 0.4, "efficient": 0.5,
        "simple": 0.4, "convenient": 0.5, "nice": 0.4, "happy": 0.7, "pleased": 0.6,
        "satisfied": 0.6, "impressed": 0.7, "favorite": 0.7, "comfortable": 0.5,
        "appreciate": 0.6, "glad": 0.6, "excited": 0.8, "delighted": 0.85,
        "relieved": 0.5, "confident": 0.5, "trust": 0.5, "recommend": 0.6,
        "better": 0.4, "best": 0.7, "good": 0.4, "like": 0.3, "prefer": 0.3,
        "clear": 0.4, "useful": 0.5, "valuable": 0.6, "straightforward": 0.5,
        "reliable": 0.5, "beautiful": 0.7, "elegant": 0.6, "powerful": 0.5,
        "quick": 0.4, "responsive": 0.5, "seamless": 0.6, "brilliant": 0.8,
        "outstanding": 0.85, "superb": 0.85, "terrific": 0.8, "lovely": 0.6,
        "pleasant": 0.5, "enjoyable": 0.6, "handy": 0.4
    ]

    // MARK: - Negative Lexicon (~55 words)

    static let negativeWords: [String: Double] = [
        "hate": -0.9, "terrible": -0.85, "awful": -0.85, "frustrate": -0.8,
        "frustrating": -0.8, "frustrated": -0.8, "difficult": -0.6, "confuse": -0.6,
        "confusing": -0.6, "confused": -0.6, "annoying": -0.7, "annoyed": -0.7,
        "problem": -0.5, "issue": -0.4, "broken": -0.7, "slow": -0.5,
        "complicated": -0.6, "tedious": -0.6, "cumbersome": -0.6, "overwhelming": -0.7,
        "stressful": -0.7, "nightmare": -0.9, "impossible": -0.8, "worst": -0.85,
        "pain": -0.6, "struggle": -0.6, "hard": -0.5, "worry": -0.5, "worried": -0.5,
        "concern": -0.4, "disappointed": -0.7, "ugly": -0.6, "useless": -0.8,
        "fail": -0.7, "failed": -0.7, "bad": -0.5, "wrong": -0.5, "poor": -0.5,
        "clunky": -0.6, "buggy": -0.7, "unreliable": -0.6, "error": -0.5,
        "crash": -0.7, "lag": -0.5, "laggy": -0.6, "awkward": -0.5,
        "unintuitive": -0.6, "cluttered": -0.5, "messy": -0.5, "dislike": -0.6,
        "horrible": -0.85, "dreadful": -0.8, "miserable": -0.7, "painful": -0.6,
        "annoying": -0.7, "tiresome": -0.5, "boring": -0.4, "ugly": -0.6
    ]

    // MARK: - Intensifiers

    static let intensifiers: Set<String> = [
        "very", "extremely", "absolutely", "totally", "completely", "really",
        "incredibly", "exceptionally", "tremendously", "utterly", "highly",
        "super", "seriously", "genuinely", "truly", "remarkably"
    ]

    // MARK: - Negators

    static let negators: Set<String> = [
        "not", "never", "don't", "doesn't", "didn't", "can't", "cannot",
        "won't", "wouldn't", "couldn't", "shouldn't", "isn't", "aren't",
        "wasn't", "weren't", "hardly", "barely", "scarcely", "no", "nor"
    ]

    // MARK: - Emotion Keywords

    /// Maps keywords to dominant emotion labels
    private static let emotionKeywords: [String: String] = [
        // Frustration
        "frustrate": "frustration", "frustrating": "frustration", "frustrated": "frustration",
        "annoying": "frustration", "annoyed": "frustration", "irritating": "frustration",
        // Delight
        "love": "delight", "amazing": "delight", "wonderful": "delight",
        "delighted": "delight", "fantastic": "delight", "awesome": "delight",
        // Confusion
        "confuse": "confusion", "confusing": "confusion", "confused": "confusion",
        "unclear": "confusion", "lost": "confusion", "puzzled": "confusion",
        // Anxiety
        "worry": "anxiety", "worried": "anxiety", "nervous": "anxiety",
        "anxious": "anxiety", "stressful": "anxiety", "overwhelm": "anxiety",
        "overwhelming": "anxiety",
        // Satisfaction
        "satisfied": "satisfaction", "pleased": "satisfaction", "happy": "satisfaction",
        "glad": "satisfaction", "content": "satisfaction",
        // Disappointment
        "disappointed": "disappointment", "letdown": "disappointment",
        "underwhelming": "disappointment", "expected": "disappointment",
        // Relief
        "relieved": "relief", "finally": "relief", "phew": "relief",
        // Excitement
        "excited": "excitement", "thrilled": "excitement", "eager": "excitement",
        "can't wait": "excitement"
    ]

    // MARK: - Thresholds

    /// Score threshold above which sentiment is classified as positive
    private let positiveThreshold: Double = 0.15

    /// Score threshold below which sentiment is classified as negative
    private let negativeThreshold: Double = -0.15

    /// Threshold for mixed sentiment: both strong positive and negative words present
    private let mixedStrengthThreshold: Double = 0.3

    /// Emotional shift detection threshold (score change > 0.4)
    private let shiftThreshold: Double = 0.4

    // MARK: - Public Methods

    /// Analyze a single utterance and return the sentiment result
    /// - Parameter utterance: The utterance to analyze
    /// - Returns: A SentimentResult with polarity, score, intensity, and dominant emotion
    func analyze(_ utterance: Utterance) -> SentimentResult {
        let text = utterance.text
        let (score, intensity, hasMixed) = scoreSentiment(text)
        let polarity = classifyPolarity(score: score, hasMixed: hasMixed)
        let dominantEmotion = detectDominantEmotion(text: text, score: score)

        let result = SentimentResult(
            utteranceId: utterance.id,
            polarity: polarity,
            score: score,
            intensity: intensity,
            dominantEmotion: dominantEmotion,
            timestamp: utterance.timestampSeconds
        )

        return result
    }

    /// Analyze a sequence of utterances for a full session
    /// Updates results, detects emotional shifts, and generates arc summary.
    /// - Parameter utterances: The ordered list of utterances to analyze
    func analyzeSession(_ utterances: [Utterance]) {
        results = utterances.map { analyze($0) }
        detectShifts()
        arcSummary = generateArcSummary()

        AppLogger.shared.debug("SentimentAnalyzer: analyzed \(utterances.count) utterances, detected \(emotionalShifts.count) shifts")
    }

    /// Generate an emotional arc summary from the current results
    /// - Returns: An EmotionalArcSummary, or nil if no results are available
    func generateArcSummary() -> EmotionalArcSummary? {
        guard !results.isEmpty else { return nil }

        let scores = results.map(\.score)
        let avgSentiment = scores.reduce(0.0, +) / Double(scores.count)
        let minScore = scores.min() ?? 0.0
        let maxScore = scores.max() ?? 0.0

        // Determine dominant polarity from average
        let dominantPolarity: SentimentPolarity
        if avgSentiment > positiveThreshold {
            dominantPolarity = .positive
        } else if avgSentiment < negativeThreshold {
            dominantPolarity = .negative
        } else {
            dominantPolarity = .neutral
        }

        // Find top 3 intensity peaks
        let sortedByIntensity = results.sorted { $0.intensity > $1.intensity }
        let peaks = Array(sortedByIntensity.prefix(3))

        // Describe the arc
        let arcDesc = describeArc(results)

        return EmotionalArcSummary(
            averageSentiment: avgSentiment,
            minSentiment: minScore,
            maxSentiment: maxScore,
            emotionalShifts: emotionalShifts,
            dominantPolarity: dominantPolarity,
            intensityPeaks: peaks,
            arcDescription: arcDesc
        )
    }

    /// Reset all analysis state
    func reset() {
        results = []
        emotionalShifts = []
        arcSummary = nil

        AppLogger.shared.debug("SentimentAnalyzer reset")
    }

    // MARK: - Private Methods

    /// Score the sentiment of a text string
    /// - Parameter text: The text to analyze
    /// - Returns: A tuple of (score, intensity, hasMixed) where score is -1..+1,
    ///   intensity is 0..1, and hasMixed indicates both strong positive and negative words
    private func scoreSentiment(_ text: String) -> (score: Double, intensity: Double, hasMixed: Bool) {
        guard !text.isEmpty else {
            return (score: 0.0, intensity: 0.0, hasMixed: false)
        }

        // Tokenize into lowercase words, removing punctuation
        let cleaned = text.lowercased()
        let words = tokenize(cleaned)

        guard !words.isEmpty else {
            return (score: 0.0, intensity: 0.0, hasMixed: false)
        }

        // Split into sentences for final-clause weighting
        let sentences = cleaned.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Determine which words belong to the final clause
        let finalClauseWords: Set<Int>
        if sentences.count > 1, let lastSentence = sentences.last {
            let lastTokens = tokenize(lastSentence)
            // Find indices of the last N words that match the final sentence
            var matchIndices = Set<Int>()
            var searchIdx = words.count - 1
            for token in lastTokens.reversed() {
                while searchIdx >= 0 {
                    if words[searchIdx] == token {
                        matchIndices.insert(searchIdx)
                        searchIdx -= 1
                        break
                    }
                    searchIdx -= 1
                }
            }
            finalClauseWords = matchIndices
        } else {
            // Single sentence: all words are in the final clause
            finalClauseWords = Set(0..<words.count)
        }

        var scoredValues: [Double] = []
        var maxPositive: Double = 0.0
        var maxNegative: Double = 0.0

        for (index, word) in words.enumerated() {
            var baseScore: Double?

            // Check positive lexicon
            if let posScore = Self.positiveWords[word] {
                baseScore = posScore
            }
            // Check negative lexicon
            if let negScore = Self.negativeWords[word] {
                baseScore = negScore
            }

            guard var wordScore = baseScore else { continue }

            // Check for negator within preceding 3 words
            let negatorRange = max(0, index - 3)..<index
            let hasNegator = negatorRange.contains { Self.negators.contains(words[$0]) }
            if hasNegator {
                wordScore = -wordScore
            }

            // Check for intensifier within preceding 2 words
            let intensifierRange = max(0, index - 2)..<index
            let hasIntensifier = intensifierRange.contains { Self.intensifiers.contains(words[$0]) }
            if hasIntensifier {
                wordScore *= 1.5
            }

            // Apply final clause weight (1.3x) for recency effect
            if finalClauseWords.contains(index) {
                wordScore *= 1.3
            }

            // Clamp to valid range
            wordScore = max(-1.0, min(1.0, wordScore))

            scoredValues.append(wordScore)

            // Track max positive and negative for mixed detection
            if wordScore > 0 {
                maxPositive = max(maxPositive, wordScore)
            } else if wordScore < 0 {
                maxNegative = max(maxNegative, abs(wordScore))
            }
        }

        guard !scoredValues.isEmpty else {
            return (score: 0.0, intensity: 0.0, hasMixed: false)
        }

        let rawScore = scoredValues.reduce(0.0, +) / Double(scoredValues.count)
        let clampedScore = max(-1.0, min(1.0, rawScore))
        let intensity = min(1.0, abs(clampedScore))
        let hasMixed = maxPositive >= mixedStrengthThreshold && maxNegative >= mixedStrengthThreshold

        return (score: clampedScore, intensity: intensity, hasMixed: hasMixed)
    }

    /// Detect the dominant emotion from text and score
    /// - Parameters:
    ///   - text: The utterance text
    ///   - score: The computed sentiment score
    /// - Returns: A dominant emotion string, or nil if none detected
    private func detectDominantEmotion(text: String, score: Double) -> String? {
        let words = tokenize(text.lowercased())

        // Count emotion occurrences
        var emotionCounts: [String: Int] = [:]
        for word in words {
            if let emotion = Self.emotionKeywords[word] {
                emotionCounts[emotion, default: 0] += 1
            }
        }

        // Return the most frequent emotion
        if let dominant = emotionCounts.max(by: { $0.value < $1.value }) {
            return dominant.key
        }

        // Fallback: infer from score if strong enough
        if score > 0.5 {
            return "delight"
        } else if score < -0.5 {
            return "frustration"
        }

        return nil
    }

    /// Classify the polarity from a score and mixed status
    /// - Parameters:
    ///   - score: The sentiment score (-1..+1)
    ///   - hasMixed: Whether both strong positive and negative words are present
    /// - Returns: The classified SentimentPolarity
    private func classifyPolarity(score: Double, hasMixed: Bool) -> SentimentPolarity {
        if hasMixed {
            return .mixed
        }
        if score > positiveThreshold {
            return .positive
        }
        if score < negativeThreshold {
            return .negative
        }
        return .neutral
    }

    /// Detect emotional shifts between consecutive results
    /// Populates the `emotionalShifts` array with significant shifts
    private func detectShifts() {
        emotionalShifts = []

        guard results.count >= 2 else { return }

        for i in 1..<results.count {
            let previous = results[i - 1]
            let current = results[i]
            let magnitude = abs(current.score - previous.score)

            if magnitude >= shiftThreshold {
                let desc = "\(previous.polarity.displayName) -> \(current.polarity.displayName)"
                    + (current.dominantEmotion.map { " (\($0))" } ?? "")

                let shift = EmotionalShift(
                    fromResult: previous,
                    toResult: current,
                    shiftMagnitude: magnitude,
                    description: desc
                )
                emotionalShifts.append(shift)
            }
        }
    }

    /// Generate a human-readable description of the emotional arc
    /// - Parameter results: The ordered sentiment results
    /// - Returns: A string describing the arc trajectory
    private func describeArc(_ results: [SentimentResult]) -> String {
        guard !results.isEmpty else {
            return "No data available"
        }

        guard results.count >= 2 else {
            return "Single data point: \(results[0].polarity.displayName.lowercased()) sentiment"
        }

        // Divide into thirds
        let thirdSize = max(1, results.count / 3)
        let startSlice = results.prefix(thirdSize)
        let midSlice: ArraySlice<SentimentResult>
        let endSlice: ArraySlice<SentimentResult>

        if results.count >= 3 {
            midSlice = results[thirdSize..<min(thirdSize * 2, results.count)]
            endSlice = results[min(thirdSize * 2, results.count)...]
        } else {
            midSlice = results[1..<results.count]
            endSlice = results[(results.count - 1)...]
        }

        func averageScore(_ slice: ArraySlice<SentimentResult>) -> Double {
            guard !slice.isEmpty else { return 0.0 }
            return slice.map(\.score).reduce(0.0, +) / Double(slice.count)
        }

        let startAvg = averageScore(startSlice)
        let midAvg = averageScore(midSlice)
        let endAvg = averageScore(endSlice)

        func describeLevel(_ score: Double) -> String {
            if score > 0.3 { return "positive" }
            if score > positiveThreshold { return "slightly positive" }
            if score < -0.3 { return "negative" }
            if score < negativeThreshold { return "slightly negative" }
            return "neutral"
        }

        let startDesc = describeLevel(startAvg)
        let midDesc = describeLevel(midAvg)
        let endDesc = describeLevel(endAvg)

        // Build arc narrative
        var parts: [String] = []
        parts.append("Started \(startDesc)")

        if midDesc != startDesc {
            parts.append("shifted \(midDesc) mid-session")
        } else {
            parts.append("remained \(midDesc) mid-session")
        }

        if endDesc != midDesc {
            if endAvg > midAvg + 0.1 {
                parts.append("recovered to \(endDesc)")
            } else if endAvg < midAvg - 0.1 {
                parts.append("declined to \(endDesc)")
            } else {
                parts.append("ended \(endDesc)")
            }
        } else {
            parts.append("ended \(endDesc)")
        }

        return parts.joined(separator: ", ")
    }

    /// Tokenize text into an array of lowercase words with punctuation removed
    /// - Parameter text: The input text
    /// - Returns: Array of word tokens
    private func tokenize(_ text: String) -> [String] {
        let allowedCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "'"))
        return text.unicodeScalars
            .map { allowedCharacters.contains($0) ? Character($0) : Character(" ") }
            .split(separator: " ")
            .map { String($0).lowercased() }
            .filter { !$0.isEmpty }
    }
}
