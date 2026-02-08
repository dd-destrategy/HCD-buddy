//
//  DemoModeView.swift
//  HCD Interview Coach
//
//  Demo Mode View
//  Wraps the demo experience with a banner, playback controls,
//  a progress bar, and simulated transcript display.
//

import SwiftUI

// MARK: - Demo Mode View

/// A SwiftUI view that wraps the full demo experience.
/// Includes a demo mode banner, playback controls (play/pause, speed, reset),
/// a progress bar showing playback position, an exit button, and a
/// simulated transcript panel.
struct DemoModeView: View {
    @StateObject private var demoProvider = DemoSessionProvider.shared
    @State private var demoSession: Session?
    @State private var selectedSpeed: PlaybackSpeed = .normal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Demo Mode Banner
            demoBanner

            Divider()

            // Playback Controls
            playbackControls

            // Progress Bar
            progressBar

            Divider()

            // Main Content Area
            mainContent

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setupDemo()
        }
        .onDisappear {
            demoProvider.stopPlayback()
        }
    }

    // MARK: - Demo Banner

    private var demoBanner: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "play.rectangle.fill")
                .font(.title3)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Demo Mode")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)

                Text("Explore the app with sample data")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onExit) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Exit Demo")
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Exit demo mode")
            .accessibilityHint("Returns to the main app without demo data")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.orange.opacity(0.08))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Demo mode banner. Explore the app with sample data.")
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: Spacing.lg) {
            // Play / Pause Button
            Button(action: togglePlayback) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: demoProvider.isPlayingDemo ? "pause.fill" : "play.fill")
                        .font(.title3)

                    Text(demoProvider.isPlayingDemo ? "Pause" : "Play")
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(isActive: demoProvider.isPlayingDemo, style: .primary)
            .accessibilityLabel(demoProvider.isPlayingDemo ? "Pause playback" : "Start playback")
            .accessibilityHint(demoProvider.isPlayingDemo
                ? "Pauses the demo transcript playback"
                : "Starts playing the demo transcript in real-time")

            // Speed Selector
            HStack(spacing: Spacing.sm) {
                Text("Speed:")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                ForEach(PlaybackSpeed.allCases) { speed in
                    Button(action: { changeSpeed(to: speed) }) {
                        Text(speed.label)
                            .font(Typography.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                    }
                    .buttonStyle(.plain)
                    .glassButton(
                        isActive: selectedSpeed == speed,
                        style: selectedSpeed == speed ? .primary : .ghost
                    )
                    .accessibilityLabel("Set playback speed to \(speed.label)")
                    .accessibilityAddTraits(selectedSpeed == speed ? .isSelected : [])
                }
            }

            Spacer()

            // Reset Button
            Button(action: resetDemo) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassButton(style: .secondary)
            .accessibilityLabel("Reset playback")
            .accessibilityHint("Returns the demo playback to the beginning")

            // Utterance Count
            Text("\(demoProvider.currentUtteranceIndex)/\(demoProvider.demoTranscript.count) utterances")
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("\(demoProvider.currentUtteranceIndex) of \(demoProvider.demoTranscript.count) utterances shown")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)

                    // Filled progress
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(Color.accentColor)
                        .frame(
                            width: max(0, geometry.size.width * demoProvider.playbackProgress),
                            height: 6
                        )
                        .animation(
                            reduceMotion ? nil : .linear(duration: 0.1),
                            value: demoProvider.playbackProgress
                        )
                }
            }
            .frame(height: 6)

            HStack {
                Text(formatSimulatedTime(progress: demoProvider.playbackProgress))
                    .font(Typography.small)
                    .foregroundColor(.secondary)

                Spacer()

                Text("30:00")
                    .font(Typography.small)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Playback progress: \(Int(demoProvider.playbackProgress * 100)) percent")
        .accessibilityValue("\(formatSimulatedTime(progress: demoProvider.playbackProgress)) of 30 minutes")
    }

    // MARK: - Main Content Area

    private var mainContent: some View {
        #if os(macOS)
        HSplitView {
            // Transcript Panel
            transcriptPanel
                .frame(minWidth: 350)

            // Side Panel with session info
            sidePanel
                .frame(minWidth: 250, maxWidth: 300)
        }
        #else
        // On iOS, use a vertical layout with transcript on top and side panel below
        VStack(spacing: 0) {
            transcriptPanel

            Divider()

            sidePanel
                .frame(maxHeight: 300)
        }
        #endif
    }

    // MARK: - Transcript Panel

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Panel header
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.accentColor)
                Text("Live Transcript")
                    .font(Typography.heading3)

                Spacer()

                Text("\(demoProvider.currentUtteranceIndex) utterances")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .glassToolbar()

            Divider()

            // Transcript content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                        let visibleEntries = Array(
                            demoProvider.demoTranscript.prefix(demoProvider.currentUtteranceIndex)
                        )
                        ForEach(Array(visibleEntries.enumerated()), id: \.offset) { index, entry in
                            demoUtteranceRow(entry: entry, index: index)
                                .id(index)
                        }
                    }
                    .padding(Spacing.lg)
                }
                .onChange(of: demoProvider.currentUtteranceIndex) { _, newValue in
                    if newValue > 0 {
                        if reduceMotion {
                            proxy.scrollTo(newValue - 1, anchor: .bottom)
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(newValue - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .glassPanel(edge: .leading)
    }

    private func demoUtteranceRow(
        entry: (speaker: Speaker, text: String, timestamp: Double),
        index: Int
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Timestamp
            Text(TimeFormatting.formatCompactTimestamp(entry.timestamp))
                .font(Typography.small)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)

            // Speaker indicator
            Image(systemName: entry.speaker.icon)
                .font(Typography.caption)
                .foregroundColor(entry.speaker == .interviewer ? .blue : .green)
                .frame(width: 16)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.speaker.displayName)
                    .font(Typography.caption)
                    .foregroundColor(entry.speaker == .interviewer ? .blue : .green)

                Text(entry.text)
                    .font(Typography.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.speaker.displayName) at \(TimeFormatting.formatCompactTimestamp(entry.timestamp)): \(entry.text)")
    }

    // MARK: - Side Panel

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Panel header
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                Text("Session Info")
                    .font(Typography.heading3)
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .glassToolbar()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Session Details
                    if let session = demoSession {
                        sessionDetailRow(label: "Participant", value: session.participantName)
                        sessionDetailRow(label: "Project", value: session.projectName)
                        sessionDetailRow(label: "Mode", value: session.sessionMode.displayName)
                        sessionDetailRow(label: "Duration", value: "30:00 (simulated)")
                    }

                    Divider()

                    // Topics
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Topics")
                            .font(Typography.bodyMedium)
                            .accessibilityAddTraits(.isHeader)

                        if let session = demoSession {
                            ForEach(session.topicStatuses, id: \.id) { topic in
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: topic.status.icon)
                                        .font(Typography.caption)
                                        .foregroundColor(topicColor(for: topic.status))

                                    Text(topic.topicName)
                                        .font(Typography.caption)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text(topic.status.displayName)
                                        .font(Typography.small)
                                        .foregroundColor(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(topic.topicName): \(topic.status.displayName)")
                            }
                        }
                    }

                    Divider()

                    // Insights
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Insights")
                            .font(Typography.bodyMedium)
                            .accessibilityAddTraits(.isHeader)

                        if let session = demoSession {
                            ForEach(session.insights, id: \.id) { insight in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: insight.source.icon)
                                            .font(Typography.small)
                                            .foregroundColor(.purple)

                                        Text(insight.theme)
                                            .font(Typography.caption)
                                            .foregroundColor(.purple)

                                        Spacer()

                                        Text(insight.formattedTimestamp)
                                            .font(Typography.small)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(insight.quote)
                                        .font(Typography.small)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(Spacing.sm)
                                .background(Color.purple.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Insight: \(insight.theme). \(insight.quote)")
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .glassPanel(edge: .trailing)
    }

    // MARK: - Helpers

    private func sessionDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(Typography.bodyMedium)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func topicColor(for status: TopicAwareness) -> Color {
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

    private func formatSimulatedTime(progress: Double) -> String {
        let totalSeconds = Int(progress * 1800.0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    private func setupDemo() {
        demoSession = demoProvider.createDemoSession()
    }

    private func togglePlayback() {
        if demoProvider.isPlayingDemo {
            demoProvider.stopPlayback()
        } else {
            demoProvider.startPlayback(speed: selectedSpeed.value)
        }
    }

    private func changeSpeed(to speed: PlaybackSpeed) {
        selectedSpeed = speed
        if demoProvider.isPlayingDemo {
            demoProvider.stopPlayback()
            demoProvider.startPlayback(speed: speed.value)
        }
    }

    private func resetDemo() {
        demoProvider.resetPlayback()
    }
}

// MARK: - Playback Speed

/// Available playback speeds for the demo mode
enum PlaybackSpeed: String, CaseIterable, Identifiable {
    case normal = "1x"
    case fast = "2x"
    case veryFast = "5x"

    var id: String { rawValue }

    var label: String { rawValue }

    var value: Double {
        switch self {
        case .normal: return 1.0
        case .fast: return 2.0
        case .veryFast: return 5.0
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Demo Mode") {
    DemoModeView(onExit: { })
        .frame(width: 900, height: 700)
}
#endif
