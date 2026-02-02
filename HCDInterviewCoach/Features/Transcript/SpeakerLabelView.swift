//
//  SpeakerLabelView.swift
//  HCDInterviewCoach
//
//  EPIC E5: Transcript Display
//  Speaker label component with color coding and toggle capability
//

import SwiftUI

// MARK: - Speaker Label View

/// Displays a speaker label with color coding and optional toggle functionality.
/// Supports manual speaker correction when auto-detection is wrong.
struct SpeakerLabelView: View {

    // MARK: - Properties

    /// The current speaker
    let speaker: Speaker

    /// Whether this label can be toggled
    var isEditable: Bool = true

    /// Whether the speaker was manually edited
    var wasManuallyEdited: Bool = false

    /// Style variant
    var style: SpeakerLabelStyle = .default

    /// Action when speaker is toggled
    var onToggle: ((Speaker) -> Void)?

    // MARK: - State

    @State private var isHovering: Bool = false
    @State private var showingPicker: Bool = false

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .default:
                defaultLabel
            case .compact:
                compactLabel
            case .badge:
                badgeLabel
            case .icon:
                iconLabel
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(speaker.displayName)
        .accessibilityHint(isEditable ? "Double tap to change speaker" : "")
        .accessibilityAddTraits(isEditable ? .isButton : [])
        .popover(isPresented: $showingPicker) {
            speakerPicker
        }
    }

    // MARK: - Style Variants

    private var defaultLabel: some View {
        Button(action: handleTap) {
            HStack(spacing: 4) {
                speakerIcon
                    .font(.system(size: 12))

                Text(speaker.displayName)
                    .font(.system(.caption, design: .default, weight: .medium))

                if wasManuallyEdited {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(speakerColor.opacity(0.6))
                }
            }
            .foregroundColor(speakerColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(speakerBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        isHovering && isEditable ? speakerColor.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .onHover { isHovering = $0 }
    }

    private var compactLabel: some View {
        Button(action: handleTap) {
            HStack(spacing: 3) {
                speakerDot

                Text(speaker.shortName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(speakerColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
    }

    private var badgeLabel: some View {
        Button(action: handleTap) {
            HStack(spacing: 4) {
                speakerIcon
                    .font(.system(size: 10))

                Text(speaker.displayName)
                    .font(.system(.caption2, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(speakerColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
    }

    private var iconLabel: some View {
        Button(action: handleTap) {
            speakerIcon
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(speakerColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(speakerBackgroundColor)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .help(speaker.displayName)
    }

    // MARK: - Components

    private var speakerIcon: some View {
        Image(systemName: speaker.icon)
    }

    private var speakerDot: some View {
        Circle()
            .fill(speakerColor)
            .frame(width: 6, height: 6)
    }

    private var speakerPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Select Speaker")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach([Speaker.interviewer, Speaker.participant, Speaker.unknown], id: \.self) { speakerOption in
                Button(action: {
                    onToggle?(speakerOption)
                    showingPicker = false
                }) {
                    HStack {
                        Image(systemName: speakerOption.icon)
                            .foregroundColor(color(for: speakerOption))
                            .frame(width: 20)

                        Text(speakerOption.displayName)

                        Spacer()

                        if speakerOption == speaker {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .frame(width: 180)
    }

    // MARK: - Colors

    private var speakerColor: Color {
        color(for: speaker)
    }

    private func color(for speaker: Speaker) -> Color {
        switch speaker {
        case .interviewer:
            return Color.blue
        case .participant:
            return Color.green
        case .unknown:
            return Color.gray
        }
    }

    private var speakerBackgroundColor: Color {
        speakerColor.opacity(colorScheme == .dark ? 0.2 : 0.1)
    }

    // MARK: - Actions

    private func handleTap() {
        guard isEditable else { return }

        // Quick toggle between interviewer and participant
        if onToggle != nil {
            let newSpeaker: Speaker = switch speaker {
            case .interviewer: .participant
            case .participant: .interviewer
            case .unknown: .interviewer
            }
            onToggle?(newSpeaker)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = "Speaker"
        if wasManuallyEdited {
            label += " (manually corrected)"
        }
        return label
    }
}

// MARK: - Speaker Label Style

/// Visual style options for speaker labels
enum SpeakerLabelStyle {
    /// Default style with icon, name, and background
    case `default`

    /// Compact style with just dot and abbreviation
    case compact

    /// Badge style with solid background
    case badge

    /// Icon only
    case icon
}

// MARK: - Speaker Extension

extension Speaker {
    /// Short name for compact displays
    var shortName: String {
        switch self {
        case .interviewer:
            return "INT"
        case .participant:
            return "PAR"
        case .unknown:
            return "UNK"
        }
    }

    /// Icon name for this speaker
    var icon: String {
        switch self {
        case .interviewer:
            return "person.fill"
        case .participant:
            return "person.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// Color for this speaker
    var color: Color {
        switch self {
        case .interviewer:
            return .blue
        case .participant:
            return .green
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SpeakerLabelView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Default style
            GroupBox("Default Style") {
                VStack(alignment: .leading, spacing: 8) {
                    SpeakerLabelView(speaker: .interviewer)
                    SpeakerLabelView(speaker: .participant)
                    SpeakerLabelView(speaker: .unknown)
                    SpeakerLabelView(speaker: .interviewer, wasManuallyEdited: true)
                }
            }

            // Compact style
            GroupBox("Compact Style") {
                HStack(spacing: 12) {
                    SpeakerLabelView(speaker: .interviewer, style: .compact)
                    SpeakerLabelView(speaker: .participant, style: .compact)
                    SpeakerLabelView(speaker: .unknown, style: .compact)
                }
            }

            // Badge style
            GroupBox("Badge Style") {
                HStack(spacing: 8) {
                    SpeakerLabelView(speaker: .interviewer, style: .badge)
                    SpeakerLabelView(speaker: .participant, style: .badge)
                }
            }

            // Icon style
            GroupBox("Icon Style") {
                HStack(spacing: 8) {
                    SpeakerLabelView(speaker: .interviewer, style: .icon)
                    SpeakerLabelView(speaker: .participant, style: .icon)
                    SpeakerLabelView(speaker: .unknown, style: .icon)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
#endif
