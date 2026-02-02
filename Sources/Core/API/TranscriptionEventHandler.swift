//
//  TranscriptionEventHandler.swift
//  HCD Interview Coach
//
//  EPIC E3-S5: Implement Transcription Event Handling
//  Parses and processes transcription events from OpenAI Realtime API
//

import Foundation

/// Handles parsing and processing of transcription events
final class TranscriptionEventHandler {
    // MARK: - Properties

    /// Current partial transcription being built
    private var currentPartialTranscription: HandlerPartialTranscription?

    /// Session start time for timestamp calculation
    private let sessionStartTime: Date

    /// Speaker detection state
    private var speakerDetection = SpeakerDetectionState()

    /// Statistics for monitoring
    private(set) var statistics = TranscriptionStatistics()

    // MARK: - Initialization

    init(sessionStartTime: Date) {
        self.sessionStartTime = sessionStartTime
    }

    // MARK: - Event Parsing

    /// Parse a transcription delta event (partial transcription)
    /// - Parameter event: Raw event from API
    /// - Returns: Transcription event or nil if parsing fails
    func parseDelta(_ event: RealtimeEvent) -> TranscriptionEvent? {
        guard event.type == .transcriptionDelta else { return nil }

        // Extract delta text
        guard let deltaText = event.payload["delta"] as? String else {
            statistics.parseErrors += 1
            return nil
        }

        // Calculate timestamp
        let timestamp = event.timestamp.timeIntervalSince(sessionStartTime)

        // Extract or infer speaker
        let speaker = extractSpeaker(from: event)

        // Extract confidence if available
        let confidence = event.payload["confidence"] as? Double ?? 0.8

        // Update or create partial transcription
        if currentPartialTranscription == nil {
            currentPartialTranscription = HandlerPartialTranscription(
                text: deltaText,
                speaker: speaker,
                startTime: timestamp
            )
        } else {
            currentPartialTranscription?.append(deltaText)
        }

        // Create event
        let transcriptionEvent = TranscriptionEvent(
            text: deltaText,
            isFinal: false,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )

        statistics.deltaEventsProcessed += 1
        return transcriptionEvent
    }

    /// Parse a transcription complete event (final transcription)
    /// - Parameter event: Raw event from API
    /// - Returns: Transcription event or nil if parsing fails
    func parseComplete(_ event: RealtimeEvent) -> TranscriptionEvent? {
        guard event.type == .transcriptionComplete else { return nil }

        // Extract final text
        guard let finalText = event.payload["transcript"] as? String else {
            statistics.parseErrors += 1
            return nil
        }

        // Calculate timestamp
        let timestamp = event.timestamp.timeIntervalSince(sessionStartTime)

        // Extract or infer speaker
        let speaker = extractSpeaker(from: event)

        // Extract confidence
        let confidence = event.payload["confidence"] as? Double ?? 0.9

        // Update speaker detection state
        speakerDetection.recordUtterance(speaker: speaker, timestamp: timestamp)

        // Clear partial transcription
        currentPartialTranscription = nil

        // Create event
        let transcriptionEvent = TranscriptionEvent(
            text: finalText,
            isFinal: true,
            speaker: speaker,
            timestamp: timestamp,
            confidence: confidence
        )

        statistics.completeEventsProcessed += 1
        statistics.totalWordsTranscribed += countWords(finalText)

        return transcriptionEvent
    }

    // MARK: - Speaker Identification

    /// Extract speaker from event or infer from context
    private func extractSpeaker(from event: RealtimeEvent) -> Speaker? {
        // First, check for explicit speaker label
        if let speakerString = event.payload["speaker"] as? String {
            return Speaker(rawValue: speakerString)
        }

        // Check for role indicator
        if let role = event.payload["role"] as? String {
            switch role.lowercased() {
            case "user", "interviewer":
                return .interviewer
            case "assistant", "participant":
                return .participant
            default:
                break
            }
        }

        // Use speaker detection heuristics
        return speakerDetection.inferSpeaker(at: event.timestamp.timeIntervalSince(sessionStartTime))
    }

    // MARK: - Utilities

    /// Count words in text
    private func countWords(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }

    /// Reset handler state (e.g., for new session)
    func reset() {
        currentPartialTranscription = nil
        speakerDetection = SpeakerDetectionState()
        statistics = TranscriptionStatistics()
    }
}

// MARK: - Supporting Types

/// Tracks partial transcription being built from deltas (local to this handler)
private struct HandlerPartialTranscription {
    var text: String
    var speaker: Speaker?
    let startTime: TimeInterval

    mutating func append(_ delta: String) {
        text += delta
    }
}

/// State for speaker detection and inference
private struct SpeakerDetectionState {
    private var lastSpeaker: Speaker?
    private var lastSpeakerTime: TimeInterval?
    private var speakerTurnThreshold: TimeInterval = 1.0 // Assume speaker change after 1s silence

    /// Record an utterance with speaker
    mutating func recordUtterance(speaker: Speaker?, timestamp: TimeInterval) {
        if let speaker = speaker {
            lastSpeaker = speaker
            lastSpeakerTime = timestamp
        }
    }

    /// Infer speaker based on timing and patterns
    func inferSpeaker(at timestamp: TimeInterval) -> Speaker? {
        guard let lastSpeaker = lastSpeaker,
              let lastTime = lastSpeakerTime else {
            // No history, assume interviewer starts
            return .interviewer
        }

        let timeSinceLastUtterance = timestamp - lastTime

        // If enough time has passed, assume speaker turn
        if timeSinceLastUtterance > speakerTurnThreshold {
            return lastSpeaker == .interviewer ? .participant : .interviewer
        }

        // Otherwise, same speaker
        return lastSpeaker
    }
}

/// Statistics for transcription processing
struct TranscriptionStatistics {
    /// Number of delta events processed
    var deltaEventsProcessed: Int = 0

    /// Number of complete events processed
    var completeEventsProcessed: Int = 0

    /// Total words transcribed
    var totalWordsTranscribed: Int = 0

    /// Number of parse errors
    var parseErrors: Int = 0

    /// Total utterances (complete events)
    var totalUtterances: Int {
        completeEventsProcessed
    }

    /// Average words per utterance
    var averageWordsPerUtterance: Double {
        guard completeEventsProcessed > 0 else { return 0.0 }
        return Double(totalWordsTranscribed) / Double(completeEventsProcessed)
    }

    /// Parse success rate
    var parseSuccessRate: Double {
        let totalEvents = deltaEventsProcessed + completeEventsProcessed
        guard totalEvents > 0 else { return 1.0 }
        return Double(totalEvents - parseErrors) / Double(totalEvents)
    }
}

// MARK: - Transcription Quality Analysis

/// Analyzes transcription quality and flags potential issues
struct TranscriptionQualityAnalyzer {
    /// Check if transcription confidence is acceptable
    /// - Parameter event: Transcription event to check
    /// - Returns: True if confidence is acceptable
    static func hasAcceptableConfidence(_ event: TranscriptionEvent) -> Bool {
        event.confidence >= 0.7
    }

    /// Check if text looks like garbled transcription
    /// - Parameter text: Transcribed text
    /// - Returns: True if text appears valid
    static func looksValid(_ text: String) -> Bool {
        // Check for minimum length
        guard text.count >= 2 else { return false }

        // Check for reasonable character distribution
        let letters = text.filter { $0.isLetter }
        let letterRatio = Double(letters.count) / Double(text.count)

        // Text should be at least 50% letters
        return letterRatio >= 0.5
    }

    /// Detect if text contains crosstalk indicators
    /// - Parameter text: Transcribed text
    /// - Returns: True if crosstalk detected
    static func hasCrosstalk(_ text: String) -> Bool {
        // Look for overlapping speech indicators
        let crosstalkPatterns = [
            "[overlapping]",
            "[crosstalk]",
            "[inaudible]",
            "[multiple speakers]"
        ]

        return crosstalkPatterns.contains { text.lowercased().contains($0) }
    }

    /// Clean transcription text (remove filler words, normalize spacing)
    /// - Parameter text: Raw transcription text
    /// - Returns: Cleaned text
    static func cleanText(_ text: String) -> String {
        var cleaned = text

        // Normalize whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned
    }
}

// MARK: - Transcription Event Buffer

/// Manages buffering of transcription events for smooth display
final class TranscriptionEventBuffer {
    private var buffer: [TranscriptionEvent] = []
    private let maxBufferSize = 100

    /// Add event to buffer
    func add(_ event: TranscriptionEvent) {
        buffer.append(event)

        // Trim buffer if too large
        if buffer.count > maxBufferSize {
            buffer.removeFirst()
        }
    }

    /// Get all buffered events
    var events: [TranscriptionEvent] {
        buffer
    }

    /// Get recent events (last N)
    func recent(count: Int) -> [TranscriptionEvent] {
        let startIndex = max(0, buffer.count - count)
        return Array(buffer[startIndex...])
    }

    /// Clear buffer
    func clear() {
        buffer.removeAll()
    }

    /// Get events in time range
    func events(from startTime: TimeInterval, to endTime: TimeInterval) -> [TranscriptionEvent] {
        buffer.filter { event in
            event.timestamp >= startTime && event.timestamp <= endTime
        }
    }

    /// Merge consecutive delta events into complete text
    func mergedText(from startTime: TimeInterval, to endTime: TimeInterval) -> String {
        let relevantEvents = events(from: startTime, to: endTime)
        return relevantEvents.map { $0.text }.joined()
    }
}

// MARK: - Speaker Confidence

/// Represents confidence in speaker identification
enum SpeakerConfidence: String, Codable {
    /// AI suggested the speaker
    case aiSuggested

    /// User confirmed the speaker
    case userConfirmed

    /// Low confidence in speaker
    case uncertain
}

/// Extended transcription event with speaker confidence
struct TranscriptionEventWithConfidence {
    let event: TranscriptionEvent
    let speakerConfidence: SpeakerConfidence

    init(event: TranscriptionEvent, speakerConfidence: SpeakerConfidence = .aiSuggested) {
        self.event = event
        self.speakerConfidence = speakerConfidence
    }
}
