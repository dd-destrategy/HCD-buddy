//
//  CoachingEventTracker.swift
//  HCD Interview Coach
//
//  EPIC E6: Coaching Engine
//  Event logging and learning system for coaching optimization
//

import Foundation
import SwiftData
import Combine

// MARK: - Coaching Event Tracker

/// Tracks coaching events for analytics and adaptive learning.
/// Logs all prompts shown, user responses, and timing data to improve
/// future coaching recommendations.
@MainActor
final class CoachingEventTracker: ObservableObject {

    // MARK: - Published Properties

    /// Events tracked during the current session
    @Published private(set) var sessionEvents: [CoachingEventRecord] = []

    /// Current session statistics
    @Published private(set) var sessionStats: SessionCoachingStats = SessionCoachingStats()

    // MARK: - Dependencies

    private let dataManager: DataManager
    private let preferences: CoachingPreferences
    private weak var currentSession: Session?

    // MARK: - Private State

    private var eventStartTimes: [UUID: Date] = [:]

    // MARK: - Initialization

    init(
        dataManager: DataManager? = nil,
        preferences: CoachingPreferences? = nil
    ) {
        self.dataManager = dataManager ?? .shared
        self.preferences = preferences ?? .shared
    }

    // MARK: - Session Management

    /// Start tracking for a new session
    func startSession(_ session: Session) {
        currentSession = session
        sessionEvents.removeAll()
        eventStartTimes.removeAll()
        sessionStats = SessionCoachingStats()
        AppLogger.shared.info("CoachingEventTracker started for session: \(session.id)")
    }

    /// End tracking for the current session and persist data
    func endSession() {
        guard let session = currentSession else { return }

        // Update session stats
        sessionStats.sessionDuration = session.durationSeconds

        // Log summary
        AppLogger.shared.info(
            """
            Coaching session ended:
            - Prompts shown: \(sessionStats.promptsShown)
            - Prompts accepted: \(sessionStats.promptsAccepted)
            - Prompts dismissed: \(sessionStats.promptsDismissed)
            - Acceptance rate: \(String(format: "%.1f%%", sessionStats.acceptanceRate * 100))
            """
        )

        // Update global preferences
        preferences.recordSessionCompleted()

        currentSession = nil
    }

    // MARK: - Event Tracking

    /// Record that a coaching prompt was shown
    /// - Parameters:
    ///   - prompt: The prompt that was shown
    ///   - timestamp: Session timestamp in seconds
    /// - Returns: The created event record
    @discardableResult
    func recordPromptShown(_ prompt: CoachingPrompt, at timestamp: TimeInterval) -> CoachingEventRecord {
        let record = CoachingEventRecord(
            id: prompt.id,
            promptType: prompt.type,
            promptText: prompt.text,
            reason: prompt.reason,
            confidence: prompt.confidence,
            timestampSeconds: timestamp,
            shownAt: Date()
        )

        sessionEvents.append(record)
        eventStartTimes[prompt.id] = Date()
        sessionStats.promptsShown += 1

        // Update preferences
        preferences.recordPromptShown()

        // Persist to SwiftData
        persistEvent(from: record)

        AppLogger.shared.info("Prompt shown: \(prompt.type.displayName) at \(formatTimestamp(timestamp))")

        return record
    }

    /// Record user response to a prompt
    /// - Parameters:
    ///   - promptId: The ID of the prompt
    ///   - response: The user's response
    func recordResponse(_ response: CoachingResponse, for promptId: UUID) {
        guard let index = sessionEvents.firstIndex(where: { $0.id == promptId }) else {
            AppLogger.shared.warning("Could not find event for prompt: \(promptId)")
            return
        }

        var record = sessionEvents[index]
        record.response = response
        record.respondedAt = Date()

        // Calculate response time
        if let startTime = eventStartTimes[promptId] {
            record.responseTimeSeconds = Date().timeIntervalSince(startTime)
        }

        sessionEvents[index] = record

        // Update stats
        switch response {
        case .accepted:
            sessionStats.promptsAccepted += 1
            sessionStats.totalResponseTime += record.responseTimeSeconds ?? 0
            preferences.recordPromptAccepted()
        case .dismissed:
            sessionStats.promptsDismissed += 1
            preferences.recordPromptDismissed()
        case .snoozed:
            sessionStats.promptsSnoozed += 1
        case .notResponded:
            sessionStats.promptsTimedOut += 1
        }

        // Update persisted event
        updatePersistedEvent(record)

        AppLogger.shared.info("Response recorded: \(response.displayName) for prompt \(promptId)")
    }

    /// Record that a prompt was auto-dismissed (timed out)
    /// - Parameter promptId: The ID of the prompt
    func recordAutoDismiss(for promptId: UUID) {
        recordResponse(.notResponded, for: promptId)
        AppLogger.shared.info("Prompt auto-dismissed: \(promptId)")
    }

    // MARK: - Learning & Analytics

    /// Get recommended thresholds based on user behavior
    func getAdaptiveThresholds() -> CoachingThresholds {
        let baseThresholds = preferences.effectiveThresholds

        // Not enough data to adapt
        guard preferences.totalPromptsShown >= 10 else {
            return baseThresholds
        }

        var adaptedThresholds = baseThresholds

        // If user dismisses most prompts, increase confidence threshold
        if preferences.dismissalRate > 0.7 {
            let newConfidence = min(0.95, baseThresholds.minimumConfidence + 0.05)
            adaptedThresholds = CoachingThresholds(
                minimumConfidence: newConfidence,
                cooldownDuration: baseThresholds.cooldownDuration * 1.2,
                speechCooldown: baseThresholds.speechCooldown,
                maxPromptsPerSession: max(2, baseThresholds.maxPromptsPerSession - 1),
                autoDismissDuration: baseThresholds.autoDismissDuration,
                sensitivityMultiplier: baseThresholds.sensitivityMultiplier * 0.8
            )
            AppLogger.shared.info("Adaptive thresholds: reduced sensitivity due to high dismissal rate")
        }

        // If user accepts most prompts, could slightly lower threshold
        if preferences.acceptanceRate > 0.8 {
            let newConfidence = max(0.70, baseThresholds.minimumConfidence - 0.03)
            adaptedThresholds = CoachingThresholds(
                minimumConfidence: newConfidence,
                cooldownDuration: baseThresholds.cooldownDuration * 0.9,
                speechCooldown: baseThresholds.speechCooldown,
                maxPromptsPerSession: baseThresholds.maxPromptsPerSession,
                autoDismissDuration: baseThresholds.autoDismissDuration,
                sensitivityMultiplier: baseThresholds.sensitivityMultiplier
            )
            AppLogger.shared.info("Adaptive thresholds: slightly increased sensitivity due to high acceptance rate")
        }

        return adaptedThresholds
    }

    /// Get analytics for a specific prompt type
    func getTypeAnalytics(for type: CoachingFunctionType) -> PromptTypeAnalytics {
        let typeEvents = sessionEvents.filter { $0.promptType == type }
        let accepted = typeEvents.filter { $0.response == .accepted }.count
        let dismissed = typeEvents.filter { $0.response == .dismissed }.count
        let total = typeEvents.count

        return PromptTypeAnalytics(
            type: type,
            totalShown: total,
            accepted: accepted,
            dismissed: dismissed,
            acceptanceRate: total > 0 ? Double(accepted) / Double(total) : 0,
            averageResponseTime: calculateAverageResponseTime(for: typeEvents)
        )
    }

    /// Get most effective prompt types based on acceptance rate
    func getMostEffectiveTypes() -> [CoachingFunctionType] {
        let analytics = CoachingFunctionType.allCases.map { getTypeAnalytics(for: $0) }
        return analytics
            .filter { $0.totalShown >= 3 } // Need minimum sample size
            .sorted { $0.acceptanceRate > $1.acceptanceRate }
            .map { $0.type }
    }

    // MARK: - History Queries

    /// Get coaching events for a specific session
    func getEvents(for session: Session) async -> [CoachingEvent] {
        return session.coachingEvents
    }

    /// Get all coaching events across sessions with pagination
    func getAllEvents(limit: Int = 100, offset: Int = 0) async throws -> [CoachingEvent] {
        guard let context = dataManager.mainContext else {
            AppLogger.shared.error("Cannot fetch coaching events: database unavailable")
            return []
        }

        var descriptor = FetchDescriptor<CoachingEvent>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset

        return try context.fetch(descriptor)
    }

    // MARK: - Private Methods

    private func persistEvent(from record: CoachingEventRecord) {
        guard let session = currentSession else { return }

        let event = CoachingEvent(
            id: record.id,
            timestampSeconds: record.timestampSeconds,
            promptText: record.promptText,
            reason: record.reason,
            userResponse: record.response,
            respondedAt: record.respondedAt,
            createdAt: record.shownAt
        )

        event.session = session
        session.coachingEvents.append(event)

        do {
            try dataManager.save()
        } catch {
            AppLogger.shared.logError(error, context: "Failed to persist coaching event")
        }
    }

    private func updatePersistedEvent(_ record: CoachingEventRecord) {
        guard let session = currentSession else { return }

        if let event = session.coachingEvents.first(where: { $0.id == record.id }) {
            event.userResponse = record.response
            event.respondedAt = record.respondedAt

            do {
                try dataManager.save()
            } catch {
                AppLogger.shared.logError(error, context: "Failed to update coaching event")
            }
        }
    }

    private func calculateAverageResponseTime(for events: [CoachingEventRecord]) -> TimeInterval {
        let responseTimes = events.compactMap { $0.responseTimeSeconds }
        guard !responseTimes.isEmpty else { return 0 }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Supporting Types

/// In-memory record of a coaching event
struct CoachingEventRecord: Identifiable, Equatable {
    let id: UUID
    let promptType: CoachingFunctionType
    let promptText: String
    let reason: String
    let confidence: Double
    let timestampSeconds: TimeInterval
    let shownAt: Date
    var response: CoachingResponse = .notResponded
    var respondedAt: Date?
    var responseTimeSeconds: TimeInterval?
}

/// Statistics for coaching within a single session
struct SessionCoachingStats: Equatable {
    var promptsShown: Int = 0
    var promptsAccepted: Int = 0
    var promptsDismissed: Int = 0
    var promptsSnoozed: Int = 0
    var promptsTimedOut: Int = 0
    var totalResponseTime: TimeInterval = 0
    var sessionDuration: TimeInterval = 0

    var acceptanceRate: Double {
        guard promptsShown > 0 else { return 0 }
        return Double(promptsAccepted) / Double(promptsShown)
    }

    var averageResponseTime: TimeInterval {
        let responded = promptsAccepted + promptsDismissed + promptsSnoozed
        guard responded > 0 else { return 0 }
        return totalResponseTime / Double(responded)
    }
}

/// Analytics for a specific prompt type
struct PromptTypeAnalytics: Equatable {
    let type: CoachingFunctionType
    let totalShown: Int
    let accepted: Int
    let dismissed: Int
    let acceptanceRate: Double
    let averageResponseTime: TimeInterval
}

// MARK: - CoachingFunctionType Extension

extension CoachingFunctionType: CaseIterable {
    static var allCases: [CoachingFunctionType] = [
        .suggestFollowUp,
        .exploreDeeper,
        .uncoveredTopic,
        .suggestPivot,
        .encouragement,
        .generalTip
    ]
}
