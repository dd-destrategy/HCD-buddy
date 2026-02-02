//
//  TranscriptionBuffer.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Buffer for managing partial and final transcriptions
//

import Foundation

// MARK: - Transcription Buffer

/// Manages buffering of partial transcriptions and assembles final utterances.
/// Handles the streaming nature of transcriptions from the Realtime API.
actor TranscriptionBuffer {
    // MARK: - Properties

    /// Current partial transcription text being accumulated
    private var currentPartialText: String = ""

    /// Current speaker for the partial transcription
    private var currentSpeaker: Speaker?

    /// Timestamp when current partial started
    private var partialStartTimestamp: TimeInterval?

    /// Buffer of finalized transcription segments
    private var finalizedSegments: [TranscriptionSegment] = []

    /// Maximum duration for a partial before auto-finalizing (prevents runaway buffers)
    private let maxPartialDuration: TimeInterval = 30.0

    /// Minimum text length to consider a segment meaningful
    private let minimumMeaningfulLength = 2

    /// Callback for when a segment is finalized
    private var onSegmentFinalized: ((TranscriptionSegment) -> Void)?

    // MARK: - Statistics

    private var totalPartialEvents = 0
    private var totalFinalEvents = 0
    private var droppedPartials = 0

    // MARK: - Initialization

    init() {}

    // MARK: - Configuration

    /// Sets the callback for when segments are finalized
    func setOnSegmentFinalized(_ handler: @escaping (TranscriptionSegment) -> Void) {
        onSegmentFinalized = handler
    }

    // MARK: - Transcription Processing

    /// Processes an incoming transcription event
    /// - Parameter event: The transcription event from the API
    /// - Returns: The resulting transcription update (partial, final, or none)
    func process(_ event: TranscriptionEvent) -> TranscriptionUpdate {
        if event.isFinal {
            return processFinalEvent(event)
        } else {
            return processPartialEvent(event)
        }
    }

    /// Processes a partial (delta) transcription event
    private func processPartialEvent(_ event: TranscriptionEvent) -> TranscriptionUpdate {
        totalPartialEvents += 1

        // Check for runaway partial
        if let startTime = partialStartTimestamp,
           (event.timestamp - startTime) > maxPartialDuration {
            // Auto-finalize the current partial
            if !currentPartialText.isEmpty {
                let autoFinalized = finalizeCurrentPartial(
                    timestamp: event.timestamp,
                    confidence: 0.7, // Lower confidence for auto-finalized
                    reason: .timeout
                )
                // Start fresh with new partial
                currentPartialText = event.text
                currentSpeaker = event.speaker
                partialStartTimestamp = event.timestamp

                if let segment = autoFinalized {
                    return .finalizedWithNewPartial(segment, event.text)
                }
            }
        }

        // Handle speaker change mid-partial
        if let existingSpeaker = currentSpeaker,
           let newSpeaker = event.speaker,
           existingSpeaker != newSpeaker {
            // Finalize current partial and start new one with new speaker
            let speakerChangeFinal = finalizeCurrentPartial(
                timestamp: event.timestamp,
                confidence: event.confidence,
                reason: .speakerChange
            )
            currentPartialText = event.text
            currentSpeaker = newSpeaker
            partialStartTimestamp = event.timestamp

            if let segment = speakerChangeFinal {
                return .finalizedWithNewPartial(segment, event.text)
            }
        }

        // Accumulate partial text
        if currentPartialText.isEmpty {
            currentPartialText = event.text
            partialStartTimestamp = event.timestamp
        } else {
            // For streaming partials, we typically replace rather than append
            // The API sends cumulative partial text
            currentPartialText = event.text
        }

        // Update speaker if provided
        if event.speaker != nil {
            currentSpeaker = event.speaker
        }

        return .partial(PartialTranscription(
            text: currentPartialText,
            speaker: currentSpeaker,
            startTimestamp: partialStartTimestamp ?? event.timestamp
        ))
    }

    /// Processes a final transcription event
    private func processFinalEvent(_ event: TranscriptionEvent) -> TranscriptionUpdate {
        totalFinalEvents += 1

        // Create the final segment
        let segment = TranscriptionSegment(
            id: UUID(),
            text: event.text,
            speaker: event.speaker ?? currentSpeaker ?? .unknown,
            startTimestamp: partialStartTimestamp ?? event.timestamp,
            endTimestamp: event.timestamp,
            confidence: event.confidence,
            finalizationReason: .apiFinalized
        )

        // Clear the partial buffer
        currentPartialText = ""
        currentSpeaker = nil
        partialStartTimestamp = nil

        // Store and notify
        if segment.text.count >= minimumMeaningfulLength {
            finalizedSegments.append(segment)
            onSegmentFinalized?(segment)
            return .finalized(segment)
        } else {
            droppedPartials += 1
            return .dropped(reason: "Text too short")
        }
    }

    /// Manually finalizes the current partial transcription
    private func finalizeCurrentPartial(
        timestamp: TimeInterval,
        confidence: Double,
        reason: FinalizationReason
    ) -> TranscriptionSegment? {
        guard !currentPartialText.isEmpty,
              currentPartialText.count >= minimumMeaningfulLength else {
            droppedPartials += 1
            return nil
        }

        let segment = TranscriptionSegment(
            id: UUID(),
            text: currentPartialText,
            speaker: currentSpeaker ?? .unknown,
            startTimestamp: partialStartTimestamp ?? timestamp,
            endTimestamp: timestamp,
            confidence: confidence,
            finalizationReason: reason
        )

        finalizedSegments.append(segment)
        onSegmentFinalized?(segment)

        currentPartialText = ""
        currentSpeaker = nil
        partialStartTimestamp = nil

        return segment
    }

    // MARK: - Buffer Management

    /// Forces finalization of any pending partial transcription
    /// - Parameter timestamp: The end timestamp to use
    /// - Returns: The finalized segment if any
    func flush(at timestamp: TimeInterval) -> TranscriptionSegment? {
        return finalizeCurrentPartial(
            timestamp: timestamp,
            confidence: 0.8,
            reason: .manualFlush
        )
    }

    /// Clears all buffered data
    func clear() {
        currentPartialText = ""
        currentSpeaker = nil
        partialStartTimestamp = nil
        finalizedSegments.removeAll()
        totalPartialEvents = 0
        totalFinalEvents = 0
        droppedPartials = 0
    }

    /// Gets all finalized segments
    func getAllSegments() -> [TranscriptionSegment] {
        return finalizedSegments
    }

    /// Gets the current partial transcription if any
    func getCurrentPartial() -> PartialTranscription? {
        guard !currentPartialText.isEmpty else { return nil }
        return PartialTranscription(
            text: currentPartialText,
            speaker: currentSpeaker,
            startTimestamp: partialStartTimestamp ?? 0
        )
    }

    // MARK: - Statistics

    /// Gets buffer statistics for monitoring
    func getStatistics() -> BufferStatistics {
        return BufferStatistics(
            totalPartialEvents: totalPartialEvents,
            totalFinalEvents: totalFinalEvents,
            droppedPartials: droppedPartials,
            currentSegmentCount: finalizedSegments.count,
            hasActivePartial: !currentPartialText.isEmpty
        )
    }
}

// MARK: - Supporting Types

/// Represents a finalized transcription segment
struct TranscriptionSegment: Identifiable, Sendable {
    let id: UUID
    let text: String
    let speaker: Speaker
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let confidence: Double
    let finalizationReason: FinalizationReason

    /// Duration of this segment in seconds
    var duration: TimeInterval {
        endTimestamp - startTimestamp
    }

    /// Word count in the segment
    var wordCount: Int {
        text.split(separator: " ").count
    }
}

/// Represents an in-progress partial transcription
struct PartialTranscription: Sendable {
    let text: String
    let speaker: Speaker?
    let startTimestamp: TimeInterval
}

/// Reason why a transcription segment was finalized
enum FinalizationReason: Sendable {
    /// Finalized by the API (normal flow)
    case apiFinalized

    /// Finalized due to speaker change
    case speakerChange

    /// Finalized due to timeout (runaway partial)
    case timeout

    /// Finalized due to session end or manual flush
    case manualFlush
}

/// Result of processing a transcription event
enum TranscriptionUpdate: Sendable {
    /// Partial transcription update
    case partial(PartialTranscription)

    /// Finalized transcription segment
    case finalized(TranscriptionSegment)

    /// Finalized previous segment and started new partial
    case finalizedWithNewPartial(TranscriptionSegment, String)

    /// Event was dropped (too short, etc.)
    case dropped(reason: String)
}

/// Statistics about the transcription buffer
struct BufferStatistics: Sendable {
    let totalPartialEvents: Int
    let totalFinalEvents: Int
    let droppedPartials: Int
    let currentSegmentCount: Int
    let hasActivePartial: Bool

    var finalizationRate: Double {
        guard totalPartialEvents > 0 else { return 0 }
        return Double(totalFinalEvents) / Double(totalPartialEvents)
    }
}

// MARK: - Transcription Stream

/// Provides an AsyncStream of transcription updates
final class TranscriptionStreamProvider: @unchecked Sendable {
    private var continuation: AsyncStream<TranscriptionUpdate>.Continuation?
    private let lock = NSLock()

    /// The async stream of transcription updates
    lazy var stream: AsyncStream<TranscriptionUpdate> = {
        AsyncStream { continuation in
            self.lock.lock()
            self.continuation = continuation
            self.lock.unlock()
        }
    }()

    /// Yields an update to the stream
    func yield(_ update: TranscriptionUpdate) {
        lock.lock()
        continuation?.yield(update)
        lock.unlock()
    }

    /// Finishes the stream
    func finish() {
        lock.lock()
        continuation?.finish()
        continuation = nil
        lock.unlock()
    }
}
