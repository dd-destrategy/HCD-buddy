//
//  CrossSessionAnalyticsView.swift
//  HCDInterviewCoach
//
//  FEATURE 3: Cross-Session Analytics & Study Organization
//  Dashboard view displaying aggregate analytics across sessions in a study.
//

import SwiftUI

// MARK: - Cross-Session Analytics Dashboard

/// A dashboard view that displays aggregate analytics across multiple interview sessions.
///
/// Layout:
/// - Study selector dropdown at top
/// - Summary cards row (total sessions, total duration, total insights, avg duration)
/// - Top themes section
/// - Quality trend list
/// - Topic coverage section
/// - Empty state when no sessions are available
struct CrossSessionAnalyticsView: View {

    // MARK: - Dependencies

    @ObservedObject var studyManager: StudyManager
    @ObservedObject var analytics: CrossSessionAnalytics
    var onDismiss: (() -> Void)?

    // MARK: - State

    @State private var sessions: [Session] = []
    @State private var isLoadingSessions: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Study selector
            studySelector
                .padding(.horizontal, Spacing.lg)

            if analytics.isAnalyzing {
                loadingView
            } else if let results = analytics.results, results.totalSessions > 0 {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        summaryCardsRow(results: results)
                        themesSection(results: results)
                        qualityTrendSection(results: results)
                        topicCoverageSection(results: results)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                }
            } else {
                emptyState
            }
        }
        .padding(.top, Spacing.lg)
        .onChange(of: studyManager.selectedStudy?.id) { _, _ in
            Task {
                await loadSessionsAndAnalyze()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Cross-session analytics dashboard")
    }

    // MARK: - Study Selector

    private var studySelector: some View {
        HStack(spacing: Spacing.md) {
            Text("Study")
                .font(Typography.heading3)
                .foregroundColor(.primary)

            Picker("Select a study", selection: Binding(
                get: { studyManager.selectedStudy?.id },
                set: { newId in
                    studyManager.selectedStudy = studyManager.studies.first { $0.id == newId }
                }
            )) {
                Text("All Sessions")
                    .tag(nil as UUID?)

                ForEach(studyManager.studies) { study in
                    Text(study.name)
                        .tag(study.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 300)
            .accessibilityLabel("Study selector")
            .accessibilityHint("Choose a study to view its analytics")

            Spacer()

            if isLoadingSessions {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Loading sessions")
            }
        }
    }

    // MARK: - Summary Cards

    private func summaryCardsRow(results: AnalyticsResults) -> some View {
        HStack(spacing: Spacing.md) {
            SummaryCard(
                title: "Sessions",
                value: "\(results.totalSessions)",
                icon: "person.2.fill",
                accessibilityValue: "\(results.totalSessions) sessions"
            )

            SummaryCard(
                title: "Total Duration",
                value: results.formattedTotalDuration,
                icon: "clock.fill",
                accessibilityValue: "Total duration \(results.formattedTotalDuration)"
            )

            SummaryCard(
                title: "Insights",
                value: "\(results.totalInsights)",
                icon: "lightbulb.fill",
                accessibilityValue: "\(results.totalInsights) insights"
            )

            SummaryCard(
                title: "Avg Duration",
                value: results.formattedAverageDuration,
                icon: "timer",
                accessibilityValue: "Average session duration \(results.formattedAverageDuration)"
            )
        }
    }

    // MARK: - Themes Section

    private func themesSection(results: AnalyticsResults) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Themes")
                .font(Typography.heading2)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            if results.topThemes.isEmpty {
                Text("No themes found. Flag insights during sessions to see themes here.")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            } else {
                let topFive = Array(results.topThemes.prefix(5))
                ForEach(Array(topFive.enumerated()), id: \.offset) { index, themeEntry in
                    ThemeRow(
                        rank: index + 1,
                        theme: themeEntry.theme,
                        count: themeEntry.count,
                        maxCount: topFive.first?.count ?? 1
                    )
                }
            }
        }
    }

    // MARK: - Quality Trend Section

    private func qualityTrendSection(results: AnalyticsResults) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Interview Quality Trend")
                .font(Typography.heading2)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            if results.interviewQualityTrend.isEmpty {
                Text("No session data available for trend analysis.")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            } else {
                ForEach(results.interviewQualityTrend) { snapshot in
                    QualitySnapshotRow(snapshot: snapshot)
                }
            }
        }
    }

    // MARK: - Topic Coverage Section

    private func topicCoverageSection(results: AnalyticsResults) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Topic Coverage")
                .font(Typography.heading2)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            if results.topicCoverageAcrossSessions.isEmpty {
                Text("No topic data available. Use templates with topics to see coverage here.")
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(results.topicCoverageAcrossSessions.enumerated()), id: \.offset) { _, entry in
                    TopicCoverageRow(
                        topic: entry.topic,
                        coverageRate: entry.coverageRate
                    )
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            ProgressView("Analyzing sessions...")
                .font(Typography.body)
                .accessibilityLabel("Analyzing sessions")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
                .accessibilityHidden(true)

            Text("No Analytics Yet")
                .font(Typography.heading2)
                .foregroundColor(.primary)

            Text("Select a study or complete interview sessions to see cross-session analytics here.")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No analytics available. Complete interview sessions to see cross-session analytics.")
    }

    // MARK: - Data Loading

    private func loadSessionsAndAnalyze() async {
        isLoadingSessions = true

        if let study = studyManager.selectedStudy {
            sessions = await studyManager.getSessionsForStudy(study)
        } else {
            // Load all sessions when no study is selected
            sessions = await loadAllSessions()
        }

        await analytics.analyze(sessions: sessions)
        isLoadingSessions = false
    }

    private func loadAllSessions() async -> [Session] {
        do {
            let context = try DataManager.shared.requireMainContext()
            let descriptor = FetchDescriptor<Session>(
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            AppLogger.shared.error("Failed to load all sessions: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Summary Card

/// A compact card displaying a single summary metric with an icon.
private struct SummaryCard: View {

    let title: String
    let value: String
    let icon: String
    let accessibilityValue: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(Typography.heading1)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.05)
                    : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(accessibilityValue)")
    }
}

// MARK: - Theme Row

/// Displays a single theme with its frequency count and a proportional bar.
private struct ThemeRow: View {

    let rank: Int
    let theme: String
    let count: Int
    let maxCount: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("#\(rank)")
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .trailing)

            Text(theme)
                .font(Typography.bodyMedium)
                .foregroundColor(.primary)
                .frame(minWidth: 120, alignment: .leading)

            GeometryReader { geometry in
                let barWidth = maxCount > 0
                    ? geometry.size.width * (CGFloat(count) / CGFloat(maxCount))
                    : 0

                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(Color.accentColor.opacity(0.6))
                    .frame(width: max(barWidth, 4), height: 20)
            }
            .frame(height: 20)

            Text("\(count)")
                .font(Typography.bodyMedium)
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Theme \(rank): \(theme), \(count) occurrences")
    }
}

// MARK: - Quality Snapshot Row

/// Displays quality metrics for a single session in the trend list.
private struct QualitySnapshotRow: View {

    let snapshot: SessionQualitySnapshot

    @Environment(\.colorScheme) private var colorScheme

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: snapshot.sessionDate)
    }

    private var topicCoverageText: String {
        if snapshot.totalTopics == 0 {
            return "No topics"
        }
        return "\(snapshot.topicsCovered)/\(snapshot.totalTopics) topics"
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)

                Text("\(String(format: "%.0f", snapshot.durationMinutes)) min")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 150, alignment: .leading)

            metricBadge(
                value: "\(snapshot.utteranceCount)",
                label: "utterances",
                icon: "text.bubble"
            )

            metricBadge(
                value: "\(snapshot.insightCount)",
                label: "insights",
                icon: "lightbulb"
            )

            metricBadge(
                value: topicCoverageText,
                label: "coverage",
                icon: "checklist"
            )

            Spacer()
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.03)
                    : Color.black.opacity(0.02))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Session on \(formattedDate), \(String(format: "%.0f", snapshot.durationMinutes)) minutes, " +
            "\(snapshot.utteranceCount) utterances, \(snapshot.insightCount) insights, \(topicCoverageText)"
        )
    }

    private func metricBadge(value: String, label: String, icon: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(value)
                .font(Typography.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

// MARK: - Topic Coverage Row

/// Displays a topic name with its coverage rate as a progress bar.
private struct TopicCoverageRow: View {

    let topic: String
    let coverageRate: Double

    @Environment(\.colorScheme) private var colorScheme

    private var coveragePercentage: Int {
        Int(coverageRate * 100)
    }

    private var coverageColor: Color {
        switch coverageRate {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(topic)
                .font(Typography.body)
                .foregroundColor(.primary)
                .frame(minWidth: 150, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                        .fill(coverageColor.opacity(0.8))
                        .frame(width: geometry.size.width * CGFloat(coverageRate), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(coveragePercentage)%")
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic): \(coveragePercentage) percent coverage across sessions")
    }
}

// MARK: - Preview

#if DEBUG
struct CrossSessionAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        CrossSessionAnalyticsView(
            studyManager: StudyManager(),
            analytics: CrossSessionAnalytics()
        )
        .frame(width: 800, height: 600)
    }
}
#endif
