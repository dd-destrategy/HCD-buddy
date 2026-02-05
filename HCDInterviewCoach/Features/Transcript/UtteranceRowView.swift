//
//  UtteranceRowView.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  Individual utterance display with full accessibility and interaction support
//

import SwiftUI

// MARK: - Utterance Row View

/// Displays a single utterance in the transcript with speaker label, timestamp, and text.
/// Supports speaker toggle, insight flagging, and search highlighting.
/// Enhanced with Liquid Glass styling for hover and selection states.
struct UtteranceRowView: View {

    // MARK: - Properties

    /// The utterance to display
    let utterance: UtteranceViewModel

    /// Whether this row is currently selected
    var isSelected: Bool = false

    /// Whether this row is focused (keyboard navigation)
    var isFocused: Bool = false

    /// Search query for highlighting matches
    var searchQuery: String?

    /// Callback when speaker is toggled
    var onSpeakerToggle: ((Speaker) -> Void)?

    /// Callback when utterance is flagged as insight
    var onFlagInsight: (() -> Void)?

    /// Callback when timestamp is tapped
    var onTimestampTap: (() -> Void)?

    /// Callback when row is selected
    var onSelect: (() -> Void)?

    // MARK: - State

    @State private var isHovering: Bool = false
    @State private var showContextMenu: Bool = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timestamp badge with glass styling
            timestampBadge
                .frame(width: 54, alignment: .trailing)

            // Speaker label with glass button styling
            speakerLabel

            // Utterance text
            utteranceText
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons (visible on hover)
            if isHovering || isSelected {
                actionButtons
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(rowBackground)
        .overlay(focusOverlay)
        .contentShape(Rectangle())
        .onTapGesture { onSelect?() }
        .onHover { isHovering = $0 }
        .contextMenu { contextMenuItems }
        .accessibilityElement(children: .combine)
        .accessibilityUtterance(
            speaker: utterance.speaker.displayName,
            text: utterance.text,
            timestamp: utterance.formattedTimestamp,
            confidence: utterance.confidence
        )
        .accessibilityActions {
            if onSpeakerToggle != nil {
                Button("Toggle Speaker") {
                    toggleSpeaker()
                }
            }
            if onFlagInsight != nil {
                Button("Flag as Insight") {
                    onFlagInsight?()
                }
            }
        }
    }

    // MARK: - Timestamp Badge

    private var timestampBadge: some View {
        TimestampView(
            timestampSeconds: utterance.timestampSeconds,
            isHighlighted: isSelected,
            style: .inline,
            onTap: onTimestampTap
        )
        .font(Typography.caption)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                .fill(timestampBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                .stroke(
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2),
                    lineWidth: 0.5
                )
        )
    }

    private var timestampBackground: Color {
        if reduceTransparency {
            return colorScheme == .dark
                ? Color(white: 0.2)
                : Color(white: 0.9)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color.black.opacity(0.03)
    }

    // MARK: - Speaker Label

    private var speakerLabel: some View {
        SpeakerLabelView(
            speaker: utterance.speaker,
            isEditable: onSpeakerToggle != nil,
            wasManuallyEdited: utterance.wasManuallyEdited,
            style: .default,
            onToggle: onSpeakerToggle
        )
        .glassButton(isActive: isSelected, style: .ghost)
    }

    // MARK: - Components

    private var utteranceText: some View {
        Group {
            if let query = searchQuery, !query.isEmpty {
                highlightedText
            } else {
                plainText
            }
        }
    }

    private var plainText: some View {
        Text(utterance.text)
            .font(Typography.body)
            .foregroundColor(.primary)
            .textSelection(.enabled)
            .lineSpacing(4)
    }

    private var highlightedText: some View {
        Text(attributedText)
            .font(Typography.body)
            .textSelection(.enabled)
            .lineSpacing(4)
    }

    private var attributedText: AttributedString {
        var attributedString = AttributedString(utterance.text)

        guard let query = searchQuery, !query.isEmpty else {
            return attributedString
        }

        let lowercaseText = utterance.text.lowercased()
        let lowercaseQuery = query.lowercased()

        var searchStartIndex = lowercaseText.startIndex

        while let range = lowercaseText.range(of: lowercaseQuery, range: searchStartIndex..<lowercaseText.endIndex) {
            // Convert String.Index to AttributedString.Index
            if let attrStart = AttributedString.Index(range.lowerBound, within: attributedString),
               let attrEnd = AttributedString.Index(range.upperBound, within: attributedString) {
                attributedString[attrStart..<attrEnd].backgroundColor = .yellow.opacity(0.4)
                attributedString[attrStart..<attrEnd].foregroundColor = .black
            }

            searchStartIndex = range.upperBound
        }

        return attributedString
    }

    private var actionButtons: some View {
        HStack(spacing: Spacing.xs) {
            // Flag as insight button
            if onFlagInsight != nil {
                ActionButton(
                    icon: "lightbulb",
                    help: "Flag as insight",
                    accessibilityLabel: "Flag as insight",
                    action: { onFlagInsight?() }
                )
            }

            // More options menu
            Menu {
                contextMenuItems
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .background(actionButtonBackground)
                    .overlay(actionButtonBorder)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26, height: 26)
            .help("More options")
            .accessibilityLabel("More options")
            .accessibilityHint("Opens menu with additional actions")
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
    }

    private var actionButtonBackground: some View {
        Circle()
            .fill(reduceTransparency
                ? (colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.9))
                : (colorScheme == .dark
                    ? Color.white.opacity(0.08)
                    : Color.black.opacity(0.05)))
    }

    private var actionButtonBorder: some View {
        Circle()
            .stroke(
                Color.white.opacity(colorScheme == .dark ? 0.12 : 0.4),
                lineWidth: 0.5
            )
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if onSpeakerToggle != nil {
            Button(action: toggleSpeaker) {
                Label("Toggle Speaker", systemImage: "person.2.fill")
            }

            Menu("Set Speaker") {
                Button(action: { onSpeakerToggle?(.interviewer) }) {
                    Label("Interviewer", systemImage: "person.fill")
                }
                Button(action: { onSpeakerToggle?(.participant) }) {
                    Label("Participant", systemImage: "person.circle.fill")
                }
                Button(action: { onSpeakerToggle?(.unknown) }) {
                    Label("Unknown", systemImage: "questionmark.circle.fill")
                }
            }
        }

        Divider()

        if onFlagInsight != nil {
            Button(action: { onFlagInsight?() }) {
                Label("Flag as Insight", systemImage: "lightbulb")
            }
        }

        Divider()

        Button(action: copyText) {
            Label("Copy Text", systemImage: "doc.on.doc")
        }

        Button(action: copyWithTimestamp) {
            Label("Copy with Timestamp", systemImage: "clock")
        }
    }

    private var rowBackground: some View {
        Group {
            if isSelected {
                ZStack {
                    // Glass base
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(reduceTransparency
                            ? selectionColorSolid
                            : selectionColor)

                    // Subtle border for glass effect
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(colorScheme == .dark ? 0.4 : 0.3),
                                    Color.accentColor.opacity(colorScheme == .dark ? 0.15 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            } else if isHovering {
                ZStack {
                    // Glass hover background
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(reduceTransparency
                            ? hoverColorSolid
                            : hoverColor)

                    // Subtle shimmer border on hover
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                            lineWidth: 0.5
                        )
                }
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private var focusOverlay: some View {
        if isFocused {
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.accentColor,
                            Color.accentColor.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
    }

    // MARK: - Colors

    private var selectionColor: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.15 : 0.08)
    }

    private var selectionColorSolid: Color {
        colorScheme == .dark
            ? Color.accentColor.opacity(0.25)
            : Color.accentColor.opacity(0.15)
    }

    private var hoverColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.03)
    }

    private var hoverColorSolid: Color {
        colorScheme == .dark
            ? Color(white: 0.22)
            : Color(white: 0.94)
    }

    // MARK: - Actions

    private func toggleSpeaker() {
        let newSpeaker: Speaker = switch utterance.speaker {
        case .interviewer: .participant
        case .participant: .interviewer
        case .unknown: .interviewer
        }
        onSpeakerToggle?(newSpeaker)
    }

    private func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(utterance.text, forType: .string)
    }

    private func copyWithTimestamp() {
        let text = "[\(utterance.formattedTimestamp)] \(utterance.speaker.displayName): \(utterance.text)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - Action Button

/// Reusable action button with glass styling for utterance row actions
private struct ActionButton: View {
    let icon: String
    let help: String
    let accessibilityLabel: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isHovered ? .primary : .secondary)
                .frame(width: 26, height: 26)
                .background(buttonBackground)
                .overlay(buttonBorder)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(help)
        .accessibilityLabel(accessibilityLabel)
    }

    private var buttonBackground: some View {
        Circle()
            .fill(reduceTransparency
                ? (colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.9))
                : (isHovered
                    ? (colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08))
                    : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))))
    }

    private var buttonBorder: some View {
        Circle()
            .stroke(
                Color.white.opacity(isHovered
                    ? (colorScheme == .dark ? 0.2 : 0.5)
                    : (colorScheme == .dark ? 0.12 : 0.4)),
                lineWidth: 0.5
            )
    }
}

// MARK: - Confidence Indicator

/// Optional confidence indicator for utterances
struct ConfidenceIndicator: View {
    let confidence: Double?

    var body: some View {
        if let confidence = confidence, confidence < 0.8 {
            Image(systemName: "waveform.badge.exclamationmark")
                .font(.system(size: 10))
                .foregroundColor(.orange)
                .help("Low confidence transcription (\(Int(confidence * 100))%)")
                .accessibilityLabel("Low confidence transcription")
                .accessibilityValue("\(Int(confidence * 100)) percent")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct UtteranceRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            UtteranceRowView(
                utterance: UtteranceViewModel(
                    from: TranscriptionEvent(
                        text: "So, can you tell me about your experience with the current system?",
                        isFinal: true,
                        speaker: .interviewer,
                        timestamp: 125
                    )
                ),
                onSpeakerToggle: { _ in },
                onFlagInsight: {}
            )

            Divider()

            UtteranceRowView(
                utterance: UtteranceViewModel(
                    from: TranscriptionEvent(
                        text: "Well, I've been using it for about two years now. The main issue I have is that the navigation is really confusing. I often get lost trying to find basic features.",
                        isFinal: true,
                        speaker: .participant,
                        timestamp: 132
                    )
                ),
                isSelected: true,
                onSpeakerToggle: { _ in },
                onFlagInsight: {}
            )

            Divider()

            UtteranceRowView(
                utterance: UtteranceViewModel(
                    from: TranscriptionEvent(
                        text: "That's really helpful. Can you walk me through a specific example of when you got lost?",
                        isFinal: true,
                        speaker: .interviewer,
                        timestamp: 158
                    )
                ),
                searchQuery: "example",
                onSpeakerToggle: { _ in },
                onFlagInsight: {}
            )
        }
        .frame(width: 600)
        .padding()
    }
}
#endif
