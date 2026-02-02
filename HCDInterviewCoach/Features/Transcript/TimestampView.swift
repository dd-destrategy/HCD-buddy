//
//  TimestampView.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  Inline timestamp display component with accessibility support
//

import SwiftUI

// MARK: - Timestamp View

/// Displays an inline timestamp for utterances in the transcript.
/// Supports click-to-navigate and full accessibility.
struct TimestampView: View {

    // MARK: - Properties

    /// Timestamp in seconds from session start
    let timestampSeconds: TimeInterval

    /// Whether this timestamp is currently selected/highlighted
    var isHighlighted: Bool = false

    /// Style variant for the timestamp
    var style: TimestampStyle = .inline

    /// Action when timestamp is clicked
    var onTap: (() -> Void)?

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var formattedTime: String {
        TimeFormatting.formatDuration(timestampSeconds)
    }

    private var accessibilityTime: String {
        TimeFormatting.formatDurationVerbose(timestampSeconds)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .inline:
                inlineTimestamp
            case .compact:
                compactTimestamp
            case .badge:
                badgeTimestamp
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timestamp")
        .accessibilityValue(accessibilityTime)
        .accessibilityHint(onTap != nil ? "Double tap to navigate to this point in the recording" : "")
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }

    // MARK: - Style Variants

    private var inlineTimestamp: some View {
        Button(action: { onTap?() }) {
            Text(formattedTime)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(isHighlighted ? highlightColor : secondaryTextColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isHighlighted ? highlightBackgroundColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var compactTimestamp: some View {
        Text(formattedTime)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(tertiaryTextColor)
    }

    private var badgeTimestamp: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text(formattedTime)
                    .font(.system(.caption2, design: .monospaced))
            }
            .foregroundColor(isHighlighted ? highlightColor : secondaryTextColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isHighlighted ? highlightBackgroundColor : badgeBackgroundColor)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isHighlighted ? highlightColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    // MARK: - Colors

    private var secondaryTextColor: Color {
        Color.secondary
    }

    private var tertiaryTextColor: Color {
        Color.secondary.opacity(0.7)
    }

    private var highlightColor: Color {
        Color.accentColor
    }

    private var highlightBackgroundColor: Color {
        Color.accentColor.opacity(0.15)
    }

    private var badgeBackgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.03)
    }
}

// MARK: - Timestamp Style

/// Visual style options for timestamp display
enum TimestampStyle {
    /// Minimal inline text
    case inline

    /// Even more compact, no background
    case compact

    /// Pill/badge style with icon
    case badge
}

// MARK: - Timestamp Formatter

/// Utility for formatting timestamps consistently
enum TimestampFormatter {

    /// Format timestamp for display
    /// - Parameter seconds: Time in seconds
    /// - Returns: Formatted time string
    static func format(_ seconds: TimeInterval) -> String {
        TimeFormatting.formatDuration(seconds)
    }

    /// Format timestamp for VoiceOver
    /// - Parameter seconds: Time in seconds
    /// - Returns: Accessible time string
    static func formatAccessible(_ seconds: TimeInterval) -> String {
        TimeFormatting.formatDurationVerbose(seconds)
    }

    /// Parse a timestamp string to seconds
    /// - Parameter string: Time string in format "MM:SS" or "HH:MM:SS"
    /// - Returns: Time in seconds, or nil if invalid
    static func parse(_ string: String) -> TimeInterval? {
        let components = string.split(separator: ":")
        guard components.count >= 2 else { return nil }

        if components.count == 2 {
            // MM:SS
            guard let minutes = Int(components[0]),
                  let seconds = Int(components[1]) else { return nil }
            return TimeInterval(minutes * 60 + seconds)
        } else if components.count == 3 {
            // HH:MM:SS
            guard let hours = Int(components[0]),
                  let minutes = Int(components[1]),
                  let seconds = Int(components[2]) else { return nil }
            return TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }

        return nil
    }
}

// MARK: - Preview

#if DEBUG
struct TimestampView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Inline styles
            GroupBox("Inline Style") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Normal:")
                        TimestampView(timestampSeconds: 125)
                    }
                    HStack {
                        Text("Highlighted:")
                        TimestampView(timestampSeconds: 125, isHighlighted: true)
                    }
                    HStack {
                        Text("Long:")
                        TimestampView(timestampSeconds: 3725)
                    }
                }
            }

            // Compact style
            GroupBox("Compact Style") {
                HStack(spacing: 16) {
                    TimestampView(timestampSeconds: 45, style: .compact)
                    TimestampView(timestampSeconds: 125, style: .compact)
                    TimestampView(timestampSeconds: 3725, style: .compact)
                }
            }

            // Badge style
            GroupBox("Badge Style") {
                VStack(alignment: .leading, spacing: 8) {
                    TimestampView(timestampSeconds: 125, style: .badge)
                    TimestampView(timestampSeconds: 125, isHighlighted: true, style: .badge)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
#endif
