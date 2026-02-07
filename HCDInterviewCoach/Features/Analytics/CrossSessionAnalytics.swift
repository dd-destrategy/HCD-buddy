//
//  CrossSessionAnalytics.swift
//  HCDInterviewCoach
//
//  FEATURE 3: Cross-Session Analytics & Study Organization
//  Computes aggregate metrics across multiple interview sessions for study-level analysis.
//

import Foundation

// MARK: - Session Quality Snapshot

/// A snapshot of quality metrics for a single session, used in trend analysis.
struct SessionQualitySnapshot: Identifiable, Equatable {

    /// Unique identifier (matches the session ID)
    let id: UUID

    /// When the session took place
    let sessionDate: Date

    /// Number of insights flagged during the session
    let insightCount: Int

    /// Total number of utterances captured
    let utteranceCount: Int

    /// Session duration in minutes
    let durationMinutes: Double

    /// Number of topics that received at least partial coverage
    let topicsCovered: Int

    /// Total number of topics defined for the session
    let totalTopics: Int

    /// Topic coverage as a percentage (0.0 to 1.0)
    var topicCoverageRate: Double {
        guard totalTopics > 0 else { return 0 }
        return Double(topicsCovered) / Double(totalTopics)
    }
}

// MARK: - Analytics Results

/// Aggregated analytics results across multiple sessions.
struct AnalyticsResults: Equatable {

    /// Total number of sessions analyzed
    let totalSessions: Int

    /// Combined duration of all sessions in seconds
    let totalDuration: TimeInterval

    /// Total utterances across all sessions
    let totalUtterances: Int

    /// Total insights across all sessions
    let totalInsights: Int

    /// Average session duration in seconds
    let averageSessionDuration: TimeInterval

    /// Most frequently occurring insight themes, sorted by count descending
    let topThemes: [(theme: String, count: Int)]

    /// Topic coverage rates across sessions — how often each topic was covered
    let topicCoverageAcrossSessions: [(topic: String, coverageRate: Double)]

    /// Per-session quality snapshots for trend visualization
    let interviewQualityTrend: [SessionQualitySnapshot]

    // MARK: - Formatted Helpers

    /// Total duration formatted as "Xh Ym"
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Average duration formatted as "Xm"
    var formattedAverageDuration: String {
        let minutes = Int(averageSessionDuration) / 60
        return "\(minutes)m"
    }

    // Equatable conformance excluding tuples (compare by contents)
    static func == (lhs: AnalyticsResults, rhs: AnalyticsResults) -> Bool {
        lhs.totalSessions == rhs.totalSessions &&
        lhs.totalDuration == rhs.totalDuration &&
        lhs.totalUtterances == rhs.totalUtterances &&
        lhs.totalInsights == rhs.totalInsights &&
        lhs.averageSessionDuration == rhs.averageSessionDuration &&
        lhs.interviewQualityTrend == rhs.interviewQualityTrend &&
        lhs.topThemes.count == rhs.topThemes.count &&
        lhs.topicCoverageAcrossSessions.count == rhs.topicCoverageAcrossSessions.count
    }
}

// MARK: - Cross-Session Analytics Engine

/// Computes aggregate analytics across multiple interview sessions.
///
/// Feed it an array of `Session` objects via `analyze(sessions:)` and it produces
/// `AnalyticsResults` including totals, theme extraction, topic coverage rates,
/// and per-session quality snapshots for trend analysis.
@MainActor
final class CrossSessionAnalytics: ObservableObject {

    // MARK: - Published Properties

    /// Whether an analysis computation is currently in progress
    @Published var isAnalyzing: Bool = false

    /// The most recent analytics results, or nil if no analysis has been performed
    @Published var results: AnalyticsResults?

    // MARK: - Analysis

    /// Computes aggregate metrics across the provided sessions.
    /// Updates `results` on completion. Safe to call from the main actor.
    /// - Parameter sessions: The sessions to analyze
    func analyze(sessions: [Session]) async {
        guard !sessions.isEmpty else {
            results = AnalyticsResults(
                totalSessions: 0,
                totalDuration: 0,
                totalUtterances: 0,
                totalInsights: 0,
                averageSessionDuration: 0,
                topThemes: [],
                topicCoverageAcrossSessions: [],
                interviewQualityTrend: []
            )
            return
        }

        isAnalyzing = true

        // Compute totals
        let totalSessions = sessions.count
        let totalDuration = sessions.reduce(0.0) { $0 + $1.totalDurationSeconds }
        let totalUtterances = sessions.reduce(0) { $0 + $1.utterances.count }
        let totalInsights = sessions.reduce(0) { $0 + $1.insights.count }
        let averageSessionDuration = totalDuration / Double(totalSessions)

        // Extract theme frequencies from insights
        let topThemes = computeTopThemes(from: sessions)

        // Compute topic coverage rates across sessions
        let topicCoverage = computeTopicCoverage(from: sessions)

        // Build per-session quality snapshots
        let qualityTrend = computeQualityTrend(from: sessions)

        results = AnalyticsResults(
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            totalUtterances: totalUtterances,
            totalInsights: totalInsights,
            averageSessionDuration: averageSessionDuration,
            topThemes: topThemes,
            topicCoverageAcrossSessions: topicCoverage,
            interviewQualityTrend: qualityTrend
        )

        isAnalyzing = false
        AppLogger.shared.info("Cross-session analysis complete: \(totalSessions) sessions, \(totalInsights) insights")
    }

    /// Resets the analytics engine, clearing all results.
    func reset() {
        isAnalyzing = false
        results = nil
    }

    // MARK: - Private Computation Helpers

    /// Extracts insight themes and counts their frequency across all sessions.
    /// Returns themes sorted by count descending.
    private func computeTopThemes(from sessions: [Session]) -> [(theme: String, count: Int)] {
        var themeCounts: [String: Int] = [:]

        for session in sessions {
            for insight in session.insights {
                let normalizedTheme = insight.theme.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalizedTheme.isEmpty else { continue }
                themeCounts[normalizedTheme, default: 0] += 1
            }
        }

        return themeCounts
            .map { (theme: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Computes how often each topic was covered across all sessions.
    /// Coverage rate is the fraction of sessions where the topic was at least partially covered.
    private func computeTopicCoverage(from sessions: [Session]) -> [(topic: String, coverageRate: Double)] {
        let sessionsWithTopics = sessions.filter { !$0.topicStatuses.isEmpty }
        guard !sessionsWithTopics.isEmpty else { return [] }

        var topicAppearances: [String: Int] = [:]
        var topicCoveredCount: [String: Int] = [:]

        for session in sessionsWithTopics {
            for topicStatus in session.topicStatuses {
                let name = topicStatus.topicName
                topicAppearances[name, default: 0] += 1
                if topicStatus.isCovered {
                    topicCoveredCount[name, default: 0] += 1
                }
            }
        }

        return topicAppearances
            .map { topic, appearances in
                let covered = topicCoveredCount[topic] ?? 0
                let rate = Double(covered) / Double(appearances)
                return (topic: topic, coverageRate: rate)
            }
            .sorted { $0.coverageRate > $1.coverageRate }
    }

    /// Builds a per-session quality snapshot for trend visualization.
    /// Sessions are sorted by start date ascending.
    private func computeQualityTrend(from sessions: [Session]) -> [SessionQualitySnapshot] {
        return sessions
            .sorted { $0.startedAt < $1.startedAt }
            .map { session in
                let topicsCovered = session.topicStatuses.filter { $0.isCovered }.count
                let totalTopics = session.topicStatuses.count
                return SessionQualitySnapshot(
                    id: session.id,
                    sessionDate: session.startedAt,
                    insightCount: session.insights.count,
                    utteranceCount: session.utterances.count,
                    durationMinutes: session.totalDurationSeconds / 60.0,
                    topicsCovered: topicsCovered,
                    totalTopics: totalTopics
                )
            }
    }
}
