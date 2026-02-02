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

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp
            TimestampView(
                timestampSeconds: utterance.timestampSeconds,
                isHighlighted: isSelected,
                style: .inline,
                onTap: onTimestampTap
            )
            .frame(width: 50, alignment: .trailing)

            // Speaker label
            SpeakerLabelView(
                speaker: utterance.speaker,
                isEditable: onSpeakerToggle != nil,
                wasManuallyEdited: utterance.wasManuallyEdited,
                style: .default,
                onToggle: onSpeakerToggle
            )

            // Utterance text
            utteranceText
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons (visible on hover)
            if isHovering || isSelected {
                actionButtons
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
            .font(.body)
            .foregroundColor(.primary)
            .textSelection(.enabled)
            .lineSpacing(4)
    }

    private var highlightedText: some View {
        Text(attributedText)
            .font(.body)
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
        HStack(spacing: 4) {
            // Flag as insight button
            if onFlagInsight != nil {
                Button(action: { onFlagInsight?() }) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .help("Flag as insight")
                .accessibilityLabel("Flag as insight")
            }

            // More options menu
            Menu {
                contextMenuItems
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24, height: 24)
            .help("More options")
        }
        .transition(.opacity.combined(with: .scale(scale: 0.8)))
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectionColor)
            } else if isHovering {
                RoundedRectangle(cornerRadius: 8)
                    .fill(hoverColor)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private var focusOverlay: some View {
        if isFocused {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.accentColor, lineWidth: 2)
        }
    }

    // MARK: - Colors

    private var selectionColor: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
    }

    private var hoverColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.03)
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
