//
//  SessionStatisticsView.swift
//  HCD Interview Coach
//
//  EPIC E10: Post-Session Summary
//  Displays session statistics in an accessible card-based layout
//

import SwiftUI

// MARK: - Session Statistics View

/// Displays key statistics from a completed interview session
struct SessionStatisticsView: View {
    let statistics: PostSessionStatistics

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateStats = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Section header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Session Statistics")
                    .font(Typography.heading3)

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            // Statistics grid
            LazyVGrid(columns: gridColumns, spacing: Spacing.md) {
                StatisticCard(
                    title: "Duration",
                    value: statistics.formattedDuration,
                    icon: "clock.fill",
                    color: .blue,
                    animate: animateStats
                )

                StatisticCard(
                    title: "Utterances",
                    value: "\(statistics.utteranceCount)",
                    icon: "text.bubble.fill",
                    color: .green,
                    animate: animateStats,
                    delay: 0.1
                )

                StatisticCard(
                    title: "Insights",
                    value: "\(statistics.insightCount)",
                    icon: "lightbulb.fill",
                    color: .orange,
                    animate: animateStats,
                    delay: 0.2
                )

                StatisticCard(
                    title: "Topics Covered",
                    value: "\(statistics.topicsCovered)/\(statistics.totalTopics)",
                    icon: "list.bullet.clipboard.fill",
                    color: .purple,
                    animate: animateStats,
                    delay: 0.3
                )
            }

            // Detailed breakdown
            VStack(alignment: .leading, spacing: Spacing.md) {
                BreakdownRow(
                    label: "Participant Utterances",
                    value: statistics.participantUtterances,
                    total: statistics.utteranceCount,
                    color: .green
                )

                BreakdownRow(
                    label: "Interviewer Utterances",
                    value: statistics.interviewerUtterances,
                    total: statistics.utteranceCount,
                    color: .blue
                )

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Avg. Utterance Length")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(statistics.averageUtteranceLength)) words")
                            .font(Typography.bodyMedium)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text("Words per Minute")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(statistics.wordsPerMinute))")
                            .font(Typography.bodyMedium)
                    }
                }
            }
            .padding(Spacing.md)
            .liquidGlass(
                material: .ultraThin,
                cornerRadius: CornerRadius.medium,
                borderStyle: .subtle,
                enableHover: false
            )
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateStats = true
                }
            } else {
                animateStats = true
            }
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Spacing.md),
            GridItem(.flexible(), spacing: Spacing.md)
        ]
    }
}

// MARK: - Statistic Card

/// Individual statistic display card with icon and value
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animate: Bool
    var delay: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showCard = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(Typography.heading1)
                .foregroundColor(.primary)

            Text(title)
                .font(Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(accentColor: color)
        .opacity(showCard ? 1 : 0)
        .scaleEffect(showCard ? 1 : 0.9)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .onChange(of: animate) { _, newValue in
            if newValue {
                if reduceMotion {
                    showCard = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
                        showCard = true
                    }
                }
            }
        }
    }
}

// MARK: - Breakdown Row

/// Shows a breakdown with progress bar
struct BreakdownRow: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(label)
                    .font(Typography.body)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(value)")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)

                Text("(\(Int(percentage * 100))%)")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) of \(total), \(Int(percentage * 100)) percent")
    }
}

// MARK: - Compact Statistics View

/// A more compact version of statistics for smaller spaces
struct CompactStatisticsView: View {
    let statistics: PostSessionStatistics

    var body: some View {
        HStack(spacing: Spacing.xl) {
            CompactStatItem(
                icon: "clock.fill",
                value: statistics.formattedDuration,
                label: "Duration",
                color: .blue
            )

            Divider()
                .frame(height: 30)

            CompactStatItem(
                icon: "text.bubble.fill",
                value: "\(statistics.utteranceCount)",
                label: "Utterances",
                color: .green
            )

            Divider()
                .frame(height: 30)

            CompactStatItem(
                icon: "lightbulb.fill",
                value: "\(statistics.insightCount)",
                label: "Insights",
                color: .orange
            )

            Divider()
                .frame(height: 30)

            CompactStatItem(
                icon: "checkmark.circle.fill",
                value: "\(Int(statistics.topicCoveragePercent))%",
                label: "Coverage",
                color: .purple
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .glassCard()
    }
}

/// Individual compact statistic item
struct CompactStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.caption)
                    .foregroundColor(color)

                Text(value)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)
            }

            Text(label)
                .font(Typography.small)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview("Session Statistics") {
    let session = Session(
        participantName: "Test User",
        projectName: "Demo Project",
        sessionMode: .full,
        totalDurationSeconds: 1845
    )

    let stats = PostSessionStatistics(session: session)

    return VStack(spacing: Spacing.xl) {
        SessionStatisticsView(statistics: stats)

        Divider()

        CompactStatisticsView(statistics: stats)
    }
    .padding(Spacing.lg)
    .frame(width: 500)
}
