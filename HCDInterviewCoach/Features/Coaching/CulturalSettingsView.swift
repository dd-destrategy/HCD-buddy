//
//  CulturalSettingsView.swift
//  HCD Interview Coach
//
//  Feature D: Cultural Sensitivity & AI Bias Controls
//  Settings view for cultural context and bias detection configuration
//

import SwiftUI

// MARK: - Cultural Settings View

/// Settings view for configuring cultural context and bias detection preferences.
///
/// Provides a preset selector grid, custom parameter sliders, bias alert toggles,
/// and a live preview of how the current settings affect coaching behavior.
struct CulturalSettingsView: View {

    @ObservedObject var culturalContext: CulturalContextManager

    @State private var isCustomExpanded: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                headerSection
                presetSelectorSection
                if culturalContext.context.preset == .custom {
                    customSettingsSection
                }
                togglesSection
                previewSection
                resetSection
            }
            .padding(Spacing.xl)
        }
        .frame(minWidth: 480)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Cultural Sensitivity Settings")
                .font(Typography.heading1)
                .foregroundColor(.hcdTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Adjust coaching behavior to respect different cultural communication styles. These settings influence silence tolerance, question pacing, and prompt formality.")
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Preset Selector

    private var presetSelectorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Communication Style Preset")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                ForEach(CulturalPreset.allCases, id: \.self) { preset in
                    presetCard(for: preset)
                }
            }
        }
    }

    private func presetCard(for preset: CulturalPreset) -> some View {
        let isSelected = culturalContext.context.preset == preset

        return Button {
            culturalContext.updatePreset(preset)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: preset.icon)
                        .font(Typography.heading2)
                        .foregroundColor(isSelected ? .accentColor : .hcdTextSecondary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Typography.body)
                            .foregroundColor(.accentColor)
                    }
                }

                Text(preset.displayName)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)

                Text(preset.description)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.displayName) communication style")
        .accessibilityHint(preset.description)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Custom Settings

    private var customSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Custom Parameters")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            VStack(spacing: Spacing.lg) {
                silenceToleranceSlider
                questionPacingSlider
                interruptionSensitivitySlider
                formalityPicker
            }
            .padding(Spacing.lg)
            .liquidGlass(material: .thin, cornerRadius: CornerRadius.large)
        }
    }

    private var silenceToleranceSlider: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Silence Tolerance")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)
                Spacer()
                Text(String(format: "%.0fs", culturalContext.context.silenceToleranceSeconds))
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextSecondary)
            }

            Slider(
                value: Binding(
                    get: { culturalContext.context.silenceToleranceSeconds },
                    set: { newValue in
                        var updated = culturalContext.context
                        updated.silenceToleranceSeconds = newValue
                        culturalContext.updateContext(updated)
                    }
                ),
                in: 2...20,
                step: 1
            )
            .accessibilityLabel("Silence tolerance")
            .accessibilityValue("\(Int(culturalContext.context.silenceToleranceSeconds)) seconds")
            .accessibilityHint("How long to wait before considering silence significant. Range: 2 to 20 seconds.")

            Text("How long to wait before considering silence significant")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
        }
    }

    private var questionPacingSlider: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Question Pacing")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)
                Spacer()
                Text(String(format: "%.1fx", culturalContext.context.questionPacingMultiplier))
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextSecondary)
            }

            Slider(
                value: Binding(
                    get: { culturalContext.context.questionPacingMultiplier },
                    set: { newValue in
                        var updated = culturalContext.context
                        updated.questionPacingMultiplier = newValue
                        culturalContext.updateContext(updated)
                    }
                ),
                in: 0.5...2.0,
                step: 0.1
            )
            .accessibilityLabel("Question pacing multiplier")
            .accessibilityValue(String(format: "%.1f times", culturalContext.context.questionPacingMultiplier))
            .accessibilityHint("Multiplier for coaching prompt cooldown. Range: 0.5 to 2.0 times.")

            Text("Multiplier for time between coaching prompts")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
        }
    }

    private var interruptionSensitivitySlider: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Interruption Sensitivity")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextPrimary)
                Spacer()
                Text(String(format: "%.0f%%", culturalContext.context.interruptionSensitivity * 100))
                    .font(Typography.bodyMedium)
                    .foregroundColor(.hcdTextSecondary)
            }

            Slider(
                value: Binding(
                    get: { culturalContext.context.interruptionSensitivity },
                    set: { newValue in
                        var updated = culturalContext.context
                        updated.interruptionSensitivity = newValue
                        culturalContext.updateContext(updated)
                    }
                ),
                in: 0...1,
                step: 0.05
            )
            .accessibilityLabel("Interruption sensitivity")
            .accessibilityValue(String(format: "%d percent", Int(culturalContext.context.interruptionSensitivity * 100)))
            .accessibilityHint("How cautious the system is about showing prompts during speech. Range: 0 to 100 percent.")

            Text("How cautious the system is about showing prompts during speech")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
        }
    }

    private var formalityPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Formality Level")
                .font(Typography.bodyMedium)
                .foregroundColor(.hcdTextPrimary)

            Picker("Formality", selection: Binding(
                get: { culturalContext.context.formalityLevel },
                set: { newValue in
                    var updated = culturalContext.context
                    updated.formalityLevel = newValue
                    culturalContext.updateContext(updated)
                }
            )) {
                ForEach(FormalityLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Formality level")
            .accessibilityHint("Controls the tone of coaching prompts: casual, neutral, or formal.")

            Text("Controls the tone and language style of coaching prompts")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
        }
    }

    // MARK: - Toggles Section

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Additional Options")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            VStack(spacing: Spacing.sm) {
                Toggle(isOn: Binding(
                    get: { culturalContext.context.showCoachingExplanations },
                    set: { newValue in
                        var updated = culturalContext.context
                        updated.showCoachingExplanations = newValue
                        culturalContext.updateContext(updated)
                    }
                )) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Show Coaching Explanations")
                            .font(Typography.bodyMedium)
                            .foregroundColor(.hcdTextPrimary)
                        Text("Display the reasoning behind each coaching prompt")
                            .font(Typography.caption)
                            .foregroundColor(.hcdTextSecondary)
                    }
                }
                .accessibilityLabel("Show coaching explanations")
                .accessibilityHint("When enabled, each coaching prompt includes an explanation of why it was triggered.")

                Divider()

                Toggle(isOn: Binding(
                    get: { culturalContext.context.enableBiasAlerts },
                    set: { newValue in
                        var updated = culturalContext.context
                        updated.enableBiasAlerts = newValue
                        culturalContext.updateContext(updated)
                    }
                )) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Enable Bias Alerts")
                            .font(Typography.bodyMedium)
                            .foregroundColor(.hcdTextPrimary)
                        Text("Alert when question patterns suggest potential bias")
                            .font(Typography.caption)
                            .foregroundColor(.hcdTextSecondary)
                    }
                }
                .accessibilityLabel("Enable bias alerts")
                .accessibilityHint("When enabled, the system detects and alerts on potential bias patterns in your interview questions.")
            }
            .padding(Spacing.lg)
            .liquidGlass(material: .thin, cornerRadius: CornerRadius.large)
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Behavior Preview")
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)

            let adjustedThresholds = culturalContext.adjustedThresholds(base: .default)

            VStack(alignment: .leading, spacing: Spacing.md) {
                previewRow(
                    label: "Silence before coaching",
                    value: String(format: "%.0fs", adjustedThresholds.speechCooldown),
                    icon: "waveform.slash"
                )

                Divider()

                previewRow(
                    label: "Question cooldown",
                    value: String(format: "%.0fs", adjustedThresholds.cooldownDuration),
                    icon: "timer"
                )

                Divider()

                previewRow(
                    label: "Interruption sensitivity",
                    value: String(format: "%.0f%%", culturalContext.context.interruptionSensitivity * 100),
                    icon: "hand.raised"
                )

                Divider()

                previewRow(
                    label: "Formality",
                    value: culturalContext.context.formalityLevel.displayName,
                    icon: "textformat"
                )

                Divider()

                previewRow(
                    label: "Bias alerts",
                    value: culturalContext.context.enableBiasAlerts ? "Enabled" : "Disabled",
                    icon: "shield.checkered"
                )
            }
            .padding(Spacing.lg)
            .liquidGlass(material: .ultraThin, cornerRadius: CornerRadius.large)
        }
    }

    private func previewRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            Text(label)
                .font(Typography.body)
                .foregroundColor(.hcdTextPrimary)

            Spacer()

            Text(value)
                .font(Typography.bodyMedium)
                .foregroundColor(.accentColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        HStack {
            Spacer()

            Button {
                culturalContext.updatePreset(.western)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(Typography.body)
                    Text("Reset to Defaults")
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .glassButton(style: .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset cultural settings to defaults")
            .accessibilityHint("Resets all cultural sensitivity settings to the Western preset defaults.")

            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CulturalSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        CulturalSettingsView(
            culturalContext: CulturalContextManager(
                storageURL: URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("preview_cultural_context.json")
            )
        )
        .frame(width: 560, height: 800)
        .preferredColorScheme(.dark)
    }
}
#endif
