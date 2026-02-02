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
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Session Statistics")
                    .font(.headline)

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            // Statistics grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
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
            VStack(alignment: .leading, spacing: 12) {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg. Utterance Length")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(statistics.averageUtteranceLength)) words")
                            .font(.body)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Words per Minute")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(Int(statistics.wordsPerMinute))")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
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
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("(\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
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
        HStack(spacing: 20) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

/// Individual compact statistic item
struct CompactStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Text(label)
                .font(.caption2)
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

    return VStack(spacing: 20) {
        SessionStatisticsView(statistics: stats)

        Divider()

        CompactStatisticsView(statistics: stats)
    }
    .padding()
    .frame(width: 500)
}
