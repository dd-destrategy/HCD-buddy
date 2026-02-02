//
//  TopicCoverageChart.swift
//  HCD Interview Coach
//
//  EPIC E10: Post-Session Summary
//  Visual representation of topic coverage in the session
//

import SwiftUI

// MARK: - Topic Coverage Chart

/// Visual chart showing topic coverage status across the session
struct TopicCoverageChart: View {
    let topicStatuses: [TopicStatus]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateChart = false
    @State private var selectedTopic: TopicStatus?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.title3)
                    .foregroundColor(.purple)

                Text("Topic Coverage")
                    .font(.headline)

                Spacer()

                // Legend
                HStack(spacing: 12) {
                    LegendItem(status: .fullyCovered, label: "Covered")
                    LegendItem(status: .partialCoverage, label: "Partial")
                    LegendItem(status: .notCovered, label: "Not Covered")
                }
                .font(.caption)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if topicStatuses.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 16) {
                    // Summary bar chart
                    TopicSummaryBar(
                        statuses: topicStatuses,
                        animate: animateChart
                    )

                    // Individual topic list
                    topicListView
                }
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .onAppear {
            if reduceMotion {
                animateChart = true
            } else {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateChart = true
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Topics Defined")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("This session did not have predefined topics to track.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Topic List

    private var topicListView: some View {
        VStack(spacing: 8) {
            ForEach(topicStatuses.sorted(by: { $0.topicName < $1.topicName }), id: \.id) { topic in
                TopicCoverageRow(
                    topic: topic,
                    isSelected: selectedTopic?.id == topic.id,
                    animate: animateChart,
                    onTap: { toggleSelection(topic) }
                )
            }
        }
    }

    private func toggleSelection(_ topic: TopicStatus) {
        if selectedTopic?.id == topic.id {
            selectedTopic = nil
        } else {
            selectedTopic = topic
        }
    }
}

// MARK: - Topic Summary Bar

/// Horizontal stacked bar showing coverage breakdown
struct TopicSummaryBar: View {
    let statuses: [TopicStatus]
    let animate: Bool

    private var coverageCounts: [TopicAwareness: Int] {
        Dictionary(grouping: statuses) { $0.status }
            .mapValues { $0.count }
    }

    private var total: Int {
        statuses.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Percentage labels
            HStack {
                ForEach(TopicAwareness.allCases, id: \.self) { status in
                    if let count = coverageCounts[status], count > 0 {
                        Text("\(percentage(for: status))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(colorForStatus(status))
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Stacked bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(TopicAwareness.allCases, id: \.self) { status in
                        if let count = coverageCounts[status], count > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForStatus(status))
                                .frame(width: barWidth(for: status, in: geometry.size.width))
                                .scaleEffect(x: animate ? 1 : 0, anchor: .leading)
                        }
                    }
                }
            }
            .frame(height: 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)

            // Count labels
            HStack(spacing: 16) {
                ForEach(TopicAwareness.allCases, id: \.self) { status in
                    if let count = coverageCounts[status], count > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForStatus(status))
                                .frame(width: 8, height: 8)

                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(count) topics \(status.displayName)")
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func percentage(for status: TopicAwareness) -> Int {
        guard total > 0, let count = coverageCounts[status] else { return 0 }
        return Int(Double(count) / Double(total) * 100)
    }

    private func barWidth(for status: TopicAwareness, in totalWidth: CGFloat) -> CGFloat {
        guard total > 0, let count = coverageCounts[status] else { return 0 }
        let spacingDeduction = CGFloat(coverageCounts.keys.count - 1) * 2
        return (totalWidth - spacingDeduction) * CGFloat(count) / CGFloat(total)
    }

    private func colorForStatus(_ status: TopicAwareness) -> Color {
        switch status {
        case .fullyCovered:
            return .green
        case .partialCoverage:
            return .orange
        case .notCovered:
            return .gray
        case .skipped:
            return .red
        }
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        for status in TopicAwareness.allCases {
            if let count = coverageCounts[status], count > 0 {
                parts.append("\(count) topics \(status.displayName)")
            }
        }
        return "Topic coverage: " + parts.joined(separator: ", ")
    }
}

// MARK: - Topic Coverage Row

/// Individual topic row showing name and status
struct TopicCoverageRow: View {
    let topic: TopicStatus
    let isSelected: Bool
    let animate: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showRow = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Status icon
                    Image(systemName: topic.status.icon)
                        .foregroundColor(colorForStatus(topic.status))
                        .font(.body)

                    // Topic name
                    Text(topic.topicName)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Status badge
                    Text(topic.status.displayName)
                        .font(.caption)
                        .foregroundColor(colorForStatus(topic.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorForStatus(topic.status).opacity(0.15))
                        .cornerRadius(4)
                }

                // Notes (if selected and available)
                if isSelected, let notes = topic.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 24)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(showRow ? 1 : 0)
        .offset(x: showRow ? 0 : -20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.topicName): \(topic.status.displayName)")
        .accessibilityHint(topic.notes.map { "Notes: \($0)" } ?? "")
        .onAppear {
            if animate {
                if reduceMotion {
                    showRow = true
                } else {
                    withAnimation(.easeOut(duration: 0.3).delay(Double.random(in: 0...0.2))) {
                        showRow = true
                    }
                }
            }
        }
        .onChange(of: animate) { _, newValue in
            if newValue && !showRow {
                if reduceMotion {
                    showRow = true
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showRow = true
                    }
                }
            }
        }
    }

    private func colorForStatus(_ status: TopicAwareness) -> Color {
        switch status {
        case .fullyCovered:
            return .green
        case .partialCoverage:
            return .orange
        case .notCovered:
            return .gray
        case .skipped:
            return .red
        }
    }
}

// MARK: - Legend Item

/// Small legend indicator for chart
struct LegendItem: View {
    let status: TopicAwareness
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForStatus(status))
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(status.displayName)")
    }

    private func colorForStatus(_ status: TopicAwareness) -> Color {
        switch status {
        case .fullyCovered:
            return .green
        case .partialCoverage:
            return .orange
        case .notCovered:
            return .gray
        case .skipped:
            return .red
        }
    }
}

// MARK: - Radial Topic Chart

/// Alternative radial visualization for topic coverage
struct RadialTopicChart: View {
    let topicStatuses: [TopicStatus]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animateChart = false

    private var coveragePercentage: Double {
        guard !topicStatuses.isEmpty else { return 0 }
        let covered = topicStatuses.filter { $0.isCovered }.count
        return Double(covered) / Double(topicStatuses.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                // Progress circle
                Circle()
                    .trim(from: 0, to: animateChart ? coveragePercentage : 0)
                    .stroke(
                        AngularGradient(
                            colors: [.green, .orange, .green],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(coveragePercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Covered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            // Counts
            HStack(spacing: 16) {
                VStack {
                    Text("\(topicStatuses.filter { $0.isFullyCovered }.count)")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("Full")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(topicStatuses.filter { $0.status == .partialCoverage }.count)")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("Partial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(topicStatuses.filter { !$0.isCovered && !$0.isSkipped }.count)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Topic coverage \(Int(coveragePercentage * 100)) percent")
        .onAppear {
            if reduceMotion {
                animateChart = true
            } else {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateChart = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Topic Coverage Chart") {
    let topics: [TopicStatus] = [
        TopicStatus(topicId: "1", topicName: "User Goals", status: .fullyCovered),
        TopicStatus(topicId: "2", topicName: "Pain Points", status: .fullyCovered),
        TopicStatus(topicId: "3", topicName: "Current Workflow", status: .partialCoverage, notes: "Discussed basic workflow but not edge cases"),
        TopicStatus(topicId: "4", topicName: "Feature Requests", status: .partialCoverage),
        TopicStatus(topicId: "5", topicName: "Integration Needs", status: .notCovered),
        TopicStatus(topicId: "6", topicName: "Team Dynamics", status: .notCovered),
        TopicStatus(topicId: "7", topicName: "Budget Constraints", status: .skipped, notes: "User declined to discuss")
    ]

    ScrollView {
        VStack(spacing: 20) {
            TopicCoverageChart(topicStatuses: topics)

            HStack {
                RadialTopicChart(topicStatuses: topics)
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(10)

                Spacer()
            }
        }
        .padding()
    }
    .frame(width: 500, height: 600)
}
