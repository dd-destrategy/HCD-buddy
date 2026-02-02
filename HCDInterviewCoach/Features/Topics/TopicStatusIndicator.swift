//
//  TopicStatusIndicator.swift
//  HCD Interview Coach
//
//  EPIC E7: Topic Awareness
//  Visual status indicator with accessibility support
//

import SwiftUI

// MARK: - Topic Status Indicator

/// Visual indicator for topic coverage status.
/// Designed for WCAG 2.1 AA compliance with:
/// - Distinct icons for each status (not relying on color alone)
/// - Sufficient color contrast
/// - VoiceOver support with descriptive labels
/// - Animation respects reduced motion preferences
struct TopicStatusIndicator: View {

    // MARK: - Properties

    let status: TopicCoverageStatus

    /// Display style for the indicator
    var style: IndicatorStyle = .standard

    /// Whether to show the status label
    var showLabel: Bool = false

    /// Whether the indicator is interactive
    var isInteractive: Bool = false

    /// Action when tapped (if interactive)
    var onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .standard:
                standardIndicator
            case .compact:
                compactIndicator
            case .badge:
                badgeIndicator
            case .progress:
                progressIndicator
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isInteractive {
                onTap?()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.accessibilityLabel)
        .accessibilityValue(status.accessibilityValue)
        .accessibilityHint(isInteractive ? status.accessibilityHint : "")
        .accessibilityAddTraits(isInteractive ? .isButton : [])
    }

    // MARK: - Standard Indicator

    private var standardIndicator: some View {
        HStack(spacing: 8) {
            // Icon with shape
            ZStack {
                // Background shape for contrast
                Circle()
                    .fill(status.backgroundColor)
                    .frame(width: 28, height: 28)

                // Status icon
                Image(systemName: status.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(status.color)
            }

            if showLabel {
                Text(status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(labelColor)
            }
        }
    }

    // MARK: - Compact Indicator

    private var compactIndicator: some View {
        Image(systemName: status.compactIconName)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(status.color)
            .padding(4)
            .background(
                Circle()
                    .fill(status.backgroundColor)
            )
    }

    // MARK: - Badge Indicator

    private var badgeIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(status.color)

            Text(status.shortLabel)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(status.backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(status.borderColor, lineWidth: 1)
                )
        )
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(status.color)
                        .frame(width: geometry.size.width * status.progressValue)
                        .animation(reduceMotion ? nil : .spring(response: 0.4), value: status)
                }
            }
            .frame(height: 6)

            // Label and percentage
            if showLabel {
                HStack {
                    Text(status.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(status.progressPercentage)%")
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var labelColor: Color {
        colorScheme == .dark ? .white.opacity(0.9) : .primary
    }
}

// MARK: - Indicator Style

extension TopicStatusIndicator {
    /// Display styles for the status indicator
    enum IndicatorStyle {
        /// Standard icon with optional label
        case standard

        /// Compact icon only
        case compact

        /// Badge with icon and text
        case badge

        /// Progress bar with percentage
        case progress
    }
}

// MARK: - Status Ring Indicator

/// Circular progress ring showing status
struct TopicStatusRing: View {

    let status: TopicCoverageStatus
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: status.progressValue)
                .stroke(
                    status.color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 0.5), value: status)

            // Center icon
            Image(systemName: status.compactIconName)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundColor(status.color)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.accessibilityLabel)
        .accessibilityValue(status.accessibilityValue)
    }
}

// MARK: - Status Legend

/// Legend showing all status levels
struct TopicStatusLegend: View {

    var isHorizontal: Bool = true
    var showLabels: Bool = true

    var body: some View {
        Group {
            if isHorizontal {
                HStack(spacing: 16) {
                    legendContent
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    legendContent
                }
            }
        }
    }

    @ViewBuilder
    private var legendContent: some View {
        ForEach(TopicCoverageStatus.allCases) { status in
            HStack(spacing: 6) {
                Image(systemName: status.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(status.color)

                if showLabels {
                    Text(status.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Animated Status Transition

/// Animates between status changes
struct AnimatedTopicStatusIndicator: View {

    let status: TopicCoverageStatus
    var style: TopicStatusIndicator.IndicatorStyle = .standard
    var showLabel: Bool = false

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TopicStatusIndicator(
            status: status,
            style: style,
            showLabel: showLabel
        )
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .onChange(of: status) { _, _ in
            guard !reduceMotion else { return }

            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Status Indicators") {
    VStack(spacing: 24) {
        // Standard indicators
        VStack(alignment: .leading, spacing: 12) {
            Text("Standard Style")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(TopicCoverageStatus.allCases) { status in
                    TopicStatusIndicator(status: status, style: .standard)
                }
            }

            HStack(spacing: 20) {
                ForEach(TopicCoverageStatus.allCases) { status in
                    TopicStatusIndicator(status: status, style: .standard, showLabel: true)
                }
            }
        }

        Divider()

        // Compact indicators
        VStack(alignment: .leading, spacing: 12) {
            Text("Compact Style")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(TopicCoverageStatus.allCases) { status in
                    TopicStatusIndicator(status: status, style: .compact)
                }
            }
        }

        Divider()

        // Badge indicators
        VStack(alignment: .leading, spacing: 12) {
            Text("Badge Style")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(TopicCoverageStatus.allCases) { status in
                    TopicStatusIndicator(status: status, style: .badge)
                }
            }
        }

        Divider()

        // Progress indicators
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Style")
                .font(.headline)

            ForEach(TopicCoverageStatus.allCases) { status in
                TopicStatusIndicator(status: status, style: .progress, showLabel: true)
                    .frame(width: 200)
            }
        }

        Divider()

        // Ring indicators
        VStack(alignment: .leading, spacing: 12) {
            Text("Ring Indicators")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(TopicCoverageStatus.allCases) { status in
                    TopicStatusRing(status: status)
                }
            }
        }

        Divider()

        // Legend
        VStack(alignment: .leading, spacing: 12) {
            Text("Legend")
                .font(.headline)

            TopicStatusLegend()
        }
    }
    .padding(24)
    .frame(width: 600)
}
