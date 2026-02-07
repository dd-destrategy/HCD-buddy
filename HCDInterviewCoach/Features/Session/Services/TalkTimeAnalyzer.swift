//
//  TalkTimeAnalyzer.swift
//  HCD Interview Coach
//
//  EPIC E4: Session Manager
//  Computes real-time talk-time ratio from utterances to help
//  interviewers maintain a healthy conversation balance.
//

import Foundation
import SwiftUI

// MARK: - Talk Time Health

/// Represents the health status of the interviewer-to-participant talk-time ratio.
/// A good interview has the participant speaking significantly more than the interviewer.
enum TalkTimeHealth: String, CaseIterable, Sendable {
    /// Interviewer is speaking less than 30% of the time — ideal balance
    case good = "good"
    /// Interviewer is speaking 30-40% of the time — approaching imbalance
    case caution = "caution"
    /// Interviewer is speaking more than 40% of the time — needs correction
    case warning = "warning"

    /// The SF Symbol icon representing this health status
    var icon: String {
        switch self {
        case .good:
            return "checkmark.circle.fill"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "xmark.octagon.fill"
        }
    }

    /// The semantic color for this health status
    var color: Color {
        switch self {
        case .good:
            return .green
        case .caution:
            return .orange
        case .warning:
            return .red
        }
    }

    /// A human-readable description of the current balance
    var description: String {
        switch self {
        case .good:
            return "Great balance — participant is leading the conversation"
        case .caution:
            return "You're talking a bit more than ideal — try asking open-ended questions"
        case .warning:
            return "Interviewer is dominating — pause and let the participant speak"
        }
    }
}

// MARK: - Talk Time Analyzer

/// Analyzes real-time talk-time ratios from utterances to help interviewers
/// maintain a healthy conversation balance where the participant speaks more.
///
/// Estimates speaking duration from word count using an average rate of 2.5 words
/// per second. Provides health indicators based on interviewer talk-time percentage.
@MainActor
final class TalkTimeAnalyzer: ObservableObject {

    // MARK: - Published Properties

    /// Interviewer's share of total speaking time (0.0 to 1.0)
    @Published private(set) var interviewerRatio: Double = 0.0

    /// Participant's share of total speaking time (0.0 to 1.0)
    @Published private(set) var participantRatio: Double = 0.0

    /// Total accumulated speaking time across all speakers in seconds
    @Published private(set) var totalSpeakingTime: TimeInterval = 0.0

    /// Current health status based on interviewer talk-time ratio
    @Published private(set) var healthStatus: TalkTimeHealth = .good

    // MARK: - Private State

    /// Accumulated speaking time for the interviewer in seconds
    private var interviewerTime: TimeInterval = 0.0

    /// Accumulated speaking time for the participant in seconds
    private var participantTime: TimeInterval = 0.0

    /// Number of utterances processed
    private var processedCount: Int = 0

    // MARK: - Constants

    /// Average speaking rate used to estimate duration from word count.
    /// Research suggests conversational English averages 2.0-3.0 words/sec;
    /// we use 2.5 as a balanced middle ground.
    static let averageWordsPerSecond: Double = 2.5

    // MARK: - Health Thresholds

    /// Interviewer ratio below this value is considered good
    static let goodThreshold: Double = 0.30

    /// Interviewer ratio below this value (but above goodThreshold) is caution
    static let cautionThreshold: Double = 0.40

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Process a single utterance, updating talk-time ratios.
    ///
    /// Duration is estimated from word count at an average rate of 2.5 words/sec.
    /// Utterances from unknown speakers are ignored.
    ///
    /// - Parameter utterance: The utterance to process
    func processUtterance(_ utterance: Utterance) {
        let estimatedDuration = estimateDuration(wordCount: utterance.wordCount)

        switch utterance.speaker {
        case .interviewer:
            interviewerTime += estimatedDuration
        case .participant:
            participantTime += estimatedDuration
        case .unknown:
            // Unknown speakers do not contribute to the ratio
            return
        }

        processedCount += 1
        recalculateRatios()
    }

    /// Process a batch of utterances, updating talk-time ratios after all are processed.
    ///
    /// More efficient than calling `processUtterance` individually as ratios are
    /// recalculated only once at the end.
    ///
    /// - Parameter utterances: The utterances to process
    func processUtterances(_ utterances: [Utterance]) {
        for utterance in utterances {
            let estimatedDuration = estimateDuration(wordCount: utterance.wordCount)

            switch utterance.speaker {
            case .interviewer:
                interviewerTime += estimatedDuration
            case .participant:
                participantTime += estimatedDuration
            case .unknown:
                continue
            }

            processedCount += 1
        }

        recalculateRatios()
    }

    /// Resets all accumulated data to initial state
    func reset() {
        interviewerTime = 0.0
        participantTime = 0.0
        totalSpeakingTime = 0.0
        interviewerRatio = 0.0
        participantRatio = 0.0
        healthStatus = .good
        processedCount = 0

        AppLogger.shared.debug("TalkTimeAnalyzer reset")
    }

    // MARK: - Computed Properties

    /// Formatted ratio string for display, e.g. "28% / 72%"
    var formattedRatio: String {
        let interviewerPercent = Int(round(interviewerRatio * 100))
        let participantPercent = Int(round(participantRatio * 100))
        return "\(interviewerPercent)% / \(participantPercent)%"
    }

    /// Number of utterances processed so far
    var utteranceCount: Int {
        processedCount
    }

    /// Interviewer speaking time in seconds
    var interviewerSpeakingTime: TimeInterval {
        interviewerTime
    }

    /// Participant speaking time in seconds
    var participantSpeakingTime: TimeInterval {
        participantTime
    }

    // MARK: - Private Methods

    /// Estimates the speaking duration from a word count
    /// - Parameter wordCount: Number of words in the utterance
    /// - Returns: Estimated duration in seconds
    private func estimateDuration(wordCount: Int) -> TimeInterval {
        guard wordCount > 0 else { return 0.0 }
        return Double(wordCount) / Self.averageWordsPerSecond
    }

    /// Recalculates all ratios and health status from accumulated times
    private func recalculateRatios() {
        totalSpeakingTime = interviewerTime + participantTime

        guard totalSpeakingTime > 0 else {
            interviewerRatio = 0.0
            participantRatio = 0.0
            healthStatus = .good
            return
        }

        interviewerRatio = interviewerTime / totalSpeakingTime
        participantRatio = participantTime / totalSpeakingTime

        // Determine health status based on interviewer ratio
        if interviewerRatio < Self.goodThreshold {
            healthStatus = .good
        } else if interviewerRatio < Self.cautionThreshold {
            healthStatus = .caution
        } else {
            healthStatus = .warning
        }
    }
}
