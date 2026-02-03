//
//  TopicRowView.swift
//  HCD Interview Coach
//
//  EPIC E7: Topic Awareness
//  Individual topic row display with interaction support
//

import SwiftUI

// MARK: - Topic Row View

/// Displays a single topic with its coverage status.
/// Supports click-to-cycle status and various display modes.
///
/// Accessibility Features:
/// - Full VoiceOver support with descriptive labels
/// - Keyboard navigation support
/// - Focus indicators
/// - Non-color dependent status indicators
struct TopicRowView: View {

    // MARK: - Properties

    let topic: TopicItem

    /// Display style for the row
    var style: RowStyle = .standard

    /// Whether status can be changed by clicking
    var isInteractive: Bool = true

    /// Action when status is cycled
    var onStatusCycle: ((String) -> Void)?

    /// Action when topic is selected for details
    var onSelect: ((TopicItem) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardRow
            case .compact:
                compactRow
            case .detailed:
                detailedRow
            case .card:
                cardRow
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            if reduceMotion {
                isHovered = hovering
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(topic.accessibilityDescription)
        .accessibilityHint(isInteractive ? "Double tap to change status" : "")
        .accessibilityAddTraits(isInteractive ? .isButton : [])
    }

    // MARK: - Standard Row

    private var standardRow: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusButton

            // Topic name
            Text(topic.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            // Right side info
            if topic.mentionCount > 0 {
                mentionBadge
            }

            // Chevron for detail navigation
            if onSelect != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackground)
        .cornerRadius(8)
        .onTapGesture {
            onSelect?(topic)
        }
    }

    // MARK: - Compact Row

    private var compactRow: some View {
        HStack(spacing: 8) {
            TopicStatusIndicator(
                status: topic.status,
                style: .compact,
                isInteractive: isInteractive
            ) {
                onStatusCycle?(topic.id)
            }

            Text(topic.name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }

    // MARK: - Detailed Row

    private var detailedRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                statusButton

                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(topic.status.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress ring
                TopicStatusRing(status: topic.status, size: 36, lineWidth: 3)
            }

            // Progress bar
            TopicStatusIndicator(
                status: topic.status,
                style: .progress,
                showLabel: false
            )

            // Metadata row
            HStack(spacing: 16) {
                if topic.mentionCount > 0 {
                    Label("\(topic.mentionCount) mentions", systemImage: "text.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let lastUpdated = topic.lastUpdated {
                    Label(lastUpdated.formatted(.relative(presentation: .named)), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if topic.isManualOverride {
                    Label("Manual", systemImage: "hand.raised.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
        }
        .padding(12)
        .background(rowBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(topic.status.borderColor, lineWidth: 1)
        )
        .onTapGesture {
            onSelect?(topic)
        }
    }

    // MARK: - Card Row

    private var cardRow: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                TopicStatusRing(status: topic.status, size: 48, lineWidth: 4)

                Spacer()

                TopicStatusIndicator(status: topic.status, style: .badge)
            }

            // Topic name
            Text(topic.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Progress bar
            TopicStatusIndicator(
                status: topic.status,
                style: .progress,
                showLabel: true
            )

            // Quick actions
            if isInteractive {
                HStack(spacing: 12) {
                    cycleButton

                    if onSelect != nil {
                        detailButton
                    }
                }
            }
        }
        .padding(16)
        .glassCard(isSelected: isHovered, accentColor: topic.status.color)
    }

    // MARK: - Subviews

    private var statusButton: some View {
        Button {
            if isInteractive {
                if reduceMotion {
                    isPressed = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                onStatusCycle?(topic.id)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if reduceMotion {
                        isPressed = false
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
                }
            }
        } label: {
            AnimatedTopicStatusIndicator(
                status: topic.status,
                style: .standard
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
        .accessibilityLabel("Status: \(topic.status.displayName)")
        .accessibilityHint("Double tap to change status")
    }

    private var mentionBadge: some View {
        Text("\(topic.mentionCount)")
            .font(.caption.monospacedDigit())
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.15))
            )
    }

    private var cycleButton: some View {
        Button {
            onStatusCycle?(topic.id)
        } label: {
            Label("Next Status", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var detailButton: some View {
        Button {
            onSelect?(topic)
        } label: {
            Label("Details", systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var rowBackground: some View {
        Group {
            if isHovered {
                Color.gray.opacity(0.08)
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - Row Style

extension TopicRowView {
    /// Display styles for topic rows
    enum RowStyle {
        /// Standard row with icon, name, and optional chevron
        case standard

        /// Minimal row for lists
        case compact

        /// Expanded row with progress and metadata
        case detailed

        /// Card layout for grid displays
        case card
    }
}

// MARK: - Topic Row Group

/// A group of topic rows with section header
struct TopicRowGroup: View {

    let title: String
    let topics: [TopicItem]
    var style: TopicRowView.RowStyle = .standard
    var isInteractive: Bool = true
    var onStatusCycle: ((String) -> Void)?
    var onSelect: ((TopicItem) -> Void)?

    @State private var isExpanded = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Button {
                if reduceMotion {
                    isExpanded.toggle()
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text("(\(topics.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), \(topics.count) topics")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")

            // Topic rows
            if isExpanded {
                ForEach(topics) { topic in
                    TopicRowView(
                        topic: topic,
                        style: style,
                        isInteractive: isInteractive,
                        onStatusCycle: onStatusCycle,
                        onSelect: onSelect
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Topic Rows") {
    let sampleTopics = [
        TopicItem(id: "1", name: "User Goals and Motivations", status: .deepDive, order: 0, confidence: 0.9, mentionCount: 5, lastUpdated: Date(), isManualOverride: false),
        TopicItem(id: "2", name: "Pain Points with Current Solutions", status: .explored, order: 1, confidence: 0.7, mentionCount: 3, lastUpdated: Date().addingTimeInterval(-300), isManualOverride: false),
        TopicItem(id: "3", name: "Daily Workflow and Habits", status: .mentioned, order: 2, confidence: 0.4, mentionCount: 1, lastUpdated: nil, isManualOverride: true),
        TopicItem(id: "4", name: "Future Feature Expectations", status: .notStarted, order: 3, confidence: 0.0, mentionCount: 0, lastUpdated: nil, isManualOverride: false)
    ]

    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // Standard rows
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard Style")
                    .font(.headline)

                ForEach(sampleTopics) { topic in
                    TopicRowView(topic: topic, style: .standard)
                }
            }

            Divider()

            // Compact rows
            VStack(alignment: .leading, spacing: 4) {
                Text("Compact Style")
                    .font(.headline)

                ForEach(sampleTopics) { topic in
                    TopicRowView(topic: topic, style: .compact)
                }
            }

            Divider()

            // Detailed rows
            VStack(alignment: .leading, spacing: 12) {
                Text("Detailed Style")
                    .font(.headline)

                ForEach(sampleTopics) { topic in
                    TopicRowView(topic: topic, style: .detailed)
                }
            }

            Divider()

            // Card rows
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Style")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sampleTopics) { topic in
                        TopicRowView(topic: topic, style: .card)
                    }
                }
            }

            Divider()

            // Grouped rows
            VStack(alignment: .leading, spacing: 12) {
                Text("Grouped Rows")
                    .font(.headline)

                TopicRowGroup(
                    title: "In Progress",
                    topics: sampleTopics.filter { $0.status == .mentioned || $0.status == .explored }
                )

                TopicRowGroup(
                    title: "Completed",
                    topics: sampleTopics.filter { $0.status == .deepDive }
                )
            }
        }
        .padding(24)
    }
    .frame(width: 600, height: 900)
}
