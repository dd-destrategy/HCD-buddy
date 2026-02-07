//
//  CoachingHistoryView.swift
//  HCD Interview Coach
//
//  Feature A: Customizable Coaching Timing & Predictable Mode
//  View for coaching prompt history, pull queue, and preview log
//

import SwiftUI

// MARK: - Coaching History View

/// Displays coaching prompt history with mode-specific UI.
/// In pull mode, shows a queue with a "Next prompt" button.
/// In preview mode, shows a log of suppressed prompts.
/// In real-time mode, shows combined delivery settings.
struct CoachingHistoryView: View {

    // MARK: - Properties

    @ObservedObject var timingSettings: CoachingTimingSettings

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            headerSection

            // Delivery mode picker
            deliveryModePicker

            // Auto-dismiss preset picker
            autoDismissSection

            Divider()
                .padding(.vertical, Spacing.xs)

            // Mode-specific content
            modeContent

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(minWidth: 320, maxWidth: 400)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Coaching history and settings")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(Typography.heading2)
                .foregroundColor(.hcdCoaching)

            Text("Coaching Timing")
                .font(Typography.heading2)
                .foregroundColor(.hcdTextPrimary)

            Spacer()

            // Mode badge
            modeBadge
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Coaching timing settings, current mode: \(timingSettings.deliveryMode.displayName)")
    }

    // MARK: - Mode Badge

    private var modeBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: timingSettings.deliveryMode.icon)
                .font(Typography.caption)
            Text(timingSettings.deliveryMode.displayName)
                .font(Typography.caption)
        }
        .foregroundColor(.hcdCoaching)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.hcdCoaching.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Delivery Mode Picker

    private var deliveryModePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Delivery Mode")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            Picker("Delivery Mode", selection: $timingSettings.deliveryMode) {
                ForEach(CoachingDeliveryMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Select delivery mode")
            .accessibilityHint("Choose how coaching prompts are delivered")

            Text(timingSettings.deliveryMode.description)
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Auto-Dismiss Section

    private var autoDismissSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Auto-Dismiss Timing")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            VStack(spacing: Spacing.xs) {
                ForEach(AutoDismissPreset.allCases, id: \.self) { preset in
                    autoDismissRow(preset)
                }
            }
        }
    }

    private func autoDismissRow(_ preset: AutoDismissPreset) -> some View {
        let isSelected = timingSettings.autoDismissPreset == preset

        return Button(action: {
            timingSettings.autoDismissPreset = preset
        }) {
            HStack(spacing: Spacing.sm) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Typography.body)
                    .foregroundColor(isSelected ? .hcdCoaching : .hcdTextTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(Typography.body)
                        .foregroundColor(.hcdTextPrimary)

                    Text(preset.description)
                        .font(Typography.small)
                        .foregroundColor(.hcdTextSecondary)
                }

                Spacer()

                if let duration = preset.duration {
                    Text("\(Int(duration))s")
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextTertiary)
                        .monospacedDigit()
                } else {
                    Image(systemName: "hand.tap")
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .glassCard(isSelected: isSelected, accentColor: .hcdCoaching)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.displayName): \(preset.description)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double-click to select")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Mode Content

    @ViewBuilder
    private var modeContent: some View {
        switch timingSettings.deliveryMode {
        case .realtime:
            realtimeModeContent
        case .pull:
            pullModeContent
        case .preview:
            previewModeContent
        }
    }

    // MARK: - Real-time Mode Content

    private var realtimeModeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader(title: "Real-time Mode", icon: "bolt.fill")

            if let duration = timingSettings.effectiveAutoDismissDuration {
                infoCard(
                    icon: "timer",
                    title: "Auto-dismiss active",
                    subtitle: "Prompts disappear after \(Int(duration)) seconds"
                )
            } else {
                infoCard(
                    icon: "hand.tap",
                    title: "Manual dismiss",
                    subtitle: "Prompts stay until you dismiss them"
                )
            }
        }
    }

    // MARK: - Pull Mode Content

    private var pullModeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                sectionHeader(title: "Pull Queue", icon: "tray.and.arrow.down")

                Spacer()

                if !timingSettings.pullModeQueue.isEmpty {
                    Button(action: { timingSettings.clearPullQueue() }) {
                        Text("Clear All")
                            .font(Typography.caption)
                            .foregroundColor(.hcdError)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear all queued prompts")
                    .accessibilityHint("Removes all prompts from the pull queue")
                }
            }

            if timingSettings.pullModeQueue.isEmpty {
                emptyState(
                    icon: "tray",
                    title: "No prompts queued",
                    subtitle: "Prompts will appear here as they are triggered during your session."
                )
            } else {
                // Queue count badge
                HStack(spacing: Spacing.sm) {
                    Text("\(timingSettings.pullQueueCount)")
                        .font(Typography.heading3)
                        .foregroundColor(.hcdCoaching)
                        .monospacedDigit()

                    Text(timingSettings.pullQueueCount == 1 ? "prompt waiting" : "prompts waiting")
                        .font(Typography.body)
                        .foregroundColor(.hcdTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(timingSettings.pullQueueCount) prompts in queue")

                // Next prompt button
                Button(action: {
                    _ = timingSettings.pullNextPrompt()
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.up.doc")
                            .font(Typography.bodyMedium)
                        Text("Pull Next Prompt")
                            .font(Typography.bodyMedium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .glassButton(isActive: true, style: .primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pull next prompt")
                .accessibilityHint("Retrieves the highest priority prompt from the queue")

                // Queue list
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(timingSettings.pullModeQueue) { prompt in
                            promptRow(prompt, status: "Queued")
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
    }

    // MARK: - Preview Mode Content

    private var previewModeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                sectionHeader(title: "Preview Log", icon: "eye")

                Spacer()

                if !timingSettings.previewLog.isEmpty {
                    Button(action: { timingSettings.clearPreviewLog() }) {
                        Text("Clear Log")
                            .font(Typography.caption)
                            .foregroundColor(.hcdError)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear preview log")
                    .accessibilityHint("Removes all logged preview prompts")
                }
            }

            if timingSettings.previewLog.isEmpty {
                emptyState(
                    icon: "eye.slash",
                    title: "No prompts logged",
                    subtitle: "Prompts that would have been shown will appear here for review."
                )
            } else {
                // Log count
                HStack(spacing: Spacing.sm) {
                    Text("\(timingSettings.previewLogCount)")
                        .font(Typography.heading3)
                        .foregroundColor(.hcdCoaching)
                        .monospacedDigit()

                    Text(timingSettings.previewLogCount == 1 ? "prompt logged" : "prompts logged")
                        .font(Typography.body)
                        .foregroundColor(.hcdTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(timingSettings.previewLogCount) prompts in preview log")

                // Log list
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(timingSettings.previewLog) { prompt in
                            promptRow(prompt, status: "Would have shown")
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
    }

    // MARK: - Shared Components

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdCoaching)

            Text(title)
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)
        }
    }

    private func promptRow(_ prompt: CoachingPrompt, status: String) -> some View {
        HStack(spacing: Spacing.sm) {
            // Type icon
            Image(systemName: prompt.type.icon)
                .font(Typography.body)
                .foregroundColor(.hcdCoaching)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.text)
                    .font(Typography.body)
                    .foregroundColor(.hcdTextPrimary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    // Confidence
                    Text("\(Int(prompt.confidence * 100))%")
                        .font(Typography.small)
                        .foregroundColor(.hcdTextTertiary)
                        .monospacedDigit()

                    // Status
                    Text(status)
                        .font(Typography.small)
                        .foregroundColor(status == "Would have shown" ? .hcdWarning : .hcdInfo)

                    // Type
                    Text(prompt.type.displayName)
                        .font(Typography.small)
                        .foregroundColor(.hcdTextSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.sm)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prompt.type.displayName): \(prompt.text), confidence \(Int(prompt.confidence * 100)) percent, status: \(status)")
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.hcdTextTertiary)

            Text(title)
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextSecondary)

            Text(subtitle)
                .font(Typography.caption)
                .foregroundColor(.hcdTextTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private func infoCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(Typography.heading3)
                .foregroundColor(.hcdCoaching)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.md)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Preview Provider

#if DEBUG
struct CoachingHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = CoachingTimingSettings()

        Group {
            CoachingHistoryView(timingSettings: settings)
                .frame(width: 380, height: 600)
                .background(Color.hcdBackground)
                .previewDisplayName("Real-time Mode")

            CoachingHistoryView(timingSettings: settings)
                .frame(width: 380, height: 600)
                .background(Color.hcdBackground)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
