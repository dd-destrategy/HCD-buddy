//
//  ColorIndependence.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - Color Independence
//

import SwiftUI

// MARK: - Topic Awareness Status

extension TopicAwarenessStatus {

    /// SF Symbol icon name for status
    /// Provides visual meaning independent of color
    var iconName: String {
        switch self {
        case .untouched:
            return "circle"
        case .touched:
            return "circle.lefthalf.filled"
        case .explored:
            return "circle.fill"
        }
    }

    /// Color for the status indicator
    var color: Color {
        switch self {
        case .untouched:
            return .gray
        case .touched:
            return Color(red: 0.5, green: 0.7, blue: 1.0) // Light blue
        case .explored:
            return .blue
        }
    }

    /// Text label for the status
    var label: String {
        switch self {
        case .untouched:
            return "Not Discussed"
        case .touched:
            return "Mentioned"
        case .explored:
            return "Explored"
        }
    }
}

// MARK: - Topic Status Indicator

/// Displays topic status with both color AND icon/text
/// Ensures accessibility for color blind users
struct TopicStatusIndicator: View {

    let status: TopicAwarenessStatus
    let showLabel: Bool

    init(status: TopicAwarenessStatus, showLabel: Bool = false) {
        self.status = status
        self.showLabel = showLabel
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .foregroundColor(status.color)
                .font(.system(size: 14, weight: .medium))

            if showLabel {
                Text(status.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.accessibilityDescription)
    }
}

// MARK: - Connection Status

enum ConnectionStatusDisplay {
    case connected
    case connecting
    case disconnected
    case reconnecting

    var iconName: String {
        switch self {
        case .connected:
            return "wifi"
        case .connecting:
            return "wifi.exclamationmark"
        case .disconnected:
            return "wifi.slash"
        case .reconnecting:
            return "arrow.clockwise"
        }
    }

    var color: Color {
        switch self {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .red
        case .reconnecting:
            return .orange
        }
    }

    var label: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .reconnecting:
            return "Reconnecting"
        }
    }
}

struct ConnectionStatusView: View {

    let status: ConnectionStatusDisplay
    let showLabel: Bool

    init(status: ConnectionStatusDisplay, showLabel: Bool = true) {
        self.status = status
        self.showLabel = showLabel
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.iconName)
                .foregroundColor(status.color)
                .symbolRenderingMode(.monochrome)

            if showLabel {
                Text(status.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Connection: \(status.label)")
    }
}

// MARK: - Audio Level Indicator

/// Audio level meter with both visual and numeric indicators
struct AudioLevelIndicator: View {

    let source: String
    let level: Double // 0.0 to 1.0
    let showNumeric: Bool

    init(source: String, level: Double, showNumeric: Bool = true) {
        self.source = source
        self.level = max(0, min(1, level))
        self.showNumeric = showNumeric
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(source)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            // Visual meter
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    // Level fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(levelColor)
                        .frame(width: geometry.size.width * level)
                }
            }
            .frame(height: 6)

            // Numeric indicator
            if showNumeric {
                Text("\(Int(level * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAudioLevel(source: source, level: level)
    }

    private var levelColor: Color {
        switch level {
        case 0..<0.3:
            return .green
        case 0.3..<0.7:
            return .yellow
        default:
            return .red
        }
    }
}

// MARK: - Insight Source Indicator

enum InsightSourceDisplay {
    case ai
    case manual

    var iconName: String {
        switch self {
        case .ai:
            return "sparkles"
        case .manual:
            return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .ai:
            return .purple
        case .manual:
            return .blue
        }
    }

    var label: String {
        switch self {
        case .ai:
            return "AI Flagged"
        case .manual:
            return "Manual"
        }
    }
}

struct InsightSourceIndicator: View {

    let source: InsightSourceDisplay
    let showLabel: Bool

    init(source: InsightSourceDisplay, showLabel: Bool = true) {
        self.source = source
        self.showLabel = showLabel
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source.iconName)
                .foregroundColor(source.color)
                .font(.system(size: 12, weight: .medium))

            if showLabel {
                Text(source.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(source.label)
    }
}

// MARK: - Recording State Indicator

enum RecordingStateDisplay {
    case idle
    case recording
    case paused

    var iconName: String {
        switch self {
        case .idle:
            return "circle"
        case .recording:
            return "record.circle.fill"
        case .paused:
            return "pause.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .paused:
            return .orange
        }
    }

    var label: String {
        switch self {
        case .idle:
            return "Not Recording"
        case .recording:
            return "Recording"
        case .paused:
            return "Paused"
        }
    }

    var isAnimated: Bool {
        self == .recording
    }
}

struct RecordingStateIndicator: View {

    let state: RecordingStateDisplay
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: state.iconName)
                .foregroundColor(state.color)
                .font(.system(size: 16, weight: .medium))
                .opacity(shouldAnimate ? (isPulsing ? 0.5 : 1.0) : 1.0)
                .animation(
                    shouldAnimate ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : nil,
                    value: isPulsing
                )
                .onAppear {
                    if shouldAnimate {
                        isPulsing = true
                    }
                }

            Text(state.label)
                .font(.caption.weight(.medium))
                .foregroundColor(state.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recording state: \(state.label)")
    }

    private var shouldAnimate: Bool {
        state.isAnimated && !reduceMotion
    }
}
