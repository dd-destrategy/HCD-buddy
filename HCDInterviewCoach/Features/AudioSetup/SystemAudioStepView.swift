//
//  SystemAudioStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - System Audio Selection Screen
//

import SwiftUI

/// Screen guiding users to select Multi-Output Device as system output
struct SystemAudioStepView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: AudioSetupViewModel

    // MARK: - State

    @State private var showAlternativeMethod = false

    // MARK: - Body

    var body: some View {
        WizardStepView(
            step: .systemAudioSelection,
            title: "System Audio Output",
            subtitle: "Set Multi-Output Device as your default sound output",
            iconName: "speaker.wave.3.fill",
            iconColor: .orange
        ) {
            systemAudioContent
        } footer: {
            systemAudioFooter
        }
        .onAppear {
            if viewModel.systemAudioStatus == .pending {
                viewModel.checkSystemAudio()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var systemAudioContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Status section
            statusSection

            // Inline tip for the most common issue
            if case .failure = viewModel.systemAudioStatus {
                InlineTroubleshootingTip(
                    message: "Not seeing Multi-Output Device? Make sure you created it in Audio MIDI Setup first (Step 3)."
                )
            }

            // Content based on status
            switch viewModel.systemAudioStatus {
            case .pending, .checking:
                checkingSection
            case .success:
                successSection
            case .failure(let message):
                failureSection(message: message)
            case .skipped:
                skippedSection
            }

            // Collapsible troubleshooting section
            if case .failure = viewModel.systemAudioStatus {
                systemAudioTroubleshootingSection
            }
        }
    }

    // MARK: - Troubleshooting

    private var systemAudioTroubleshootingSection: some View {
        TroubleshootingSection(tips: [
            .init(text: "Open System Settings > Sound and select your Multi-Output Device under Output."),
            .init(text: "Alternatively, hold Option and click the Sound icon in the menu bar to switch output."),
            .init(text: "If Multi-Output Device is not listed, go back to Step 3 and create it in Audio MIDI Setup."),
            .init(text: "Some Bluetooth headphones may override the output selection when connected."),
            .init(text: "If the auto-detection is not working, use the \"I've Set Up System Audio\" button below to proceed.")
        ])
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack {
            Text("Status:")
                .font(Typography.heading3)
                .foregroundColor(.primary)

            SetupStatusBadge(status: viewModel.systemAudioStatus)

            Spacer()

            if viewModel.systemAudioStatus != .checking {
                Button("Re-check") {
                    viewModel.checkSystemAudio()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isChecking)
                .accessibilityLabel("Check system audio output again")
            }
        }
    }

    // MARK: - Checking Section

    private var checkingSection: some View {
        VStack(alignment: .center, spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Checking system audio output...")
                .font(Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .tip,
                title: "System Audio Configured",
                message: "Your Multi-Output Device is set as the system sound output. Audio will be sent to both your speakers and captured for analysis."
            )

            // Important reminder
            WizardInfoBox(
                style: .info,
                title: "During Interviews",
                message: "Before starting an interview, make sure your Multi-Output Device is still selected. You can quickly check using the menu bar sound icon or Control Center."
            )
        }
    }

    // MARK: - Failure Section

    private func failureSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Structured error view (if available)
            if let setupError = viewModel.currentSetupError {
                SetupErrorView(
                    error: setupError,
                    onRetry: { viewModel.checkSystemAudio() },
                    onAction: { viewModel.openSystemSoundSettings() },
                    actionLabel: "Open Sound Settings",
                    actionIcon: "gearshape.fill"
                )
            } else {
                // Fallback for legacy error messages
                WizardInfoBox(
                    style: .warning,
                    title: "Multi-Output Device Not Selected",
                    message: message
                )
            }

            // Quick setup guide
            quickSetupGuide

            Divider()

            // Open System Settings button
            openSystemSettingsButton

            // Alternative method
            if showAlternativeMethod {
                alternativeMethod
            }

            Button(action: {
                withAnimation {
                    showAlternativeMethod.toggle()
                }
            }) {
                HStack {
                    Text(showAlternativeMethod ? "Hide Alternative Method" : "Show Alternative Method")
                    Image(systemName: showAlternativeMethod ? "chevron.up" : "chevron.down")
                }
                .font(Typography.body)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)

            // Manual confirmation
            manualConfirmation
        }
    }

    // MARK: - Skipped Section

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .warning,
                title: "Step Skipped",
                message: "System audio output should be set to your Multi-Output Device for audio capture to work. You can configure this manually later."
            )
        }
    }

    // MARK: - Quick Setup Guide

    private var quickSetupGuide: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Quick Setup")
                .font(Typography.heading3)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(
                    number: 1,
                    title: "Open System Settings",
                    description: "Click the button below or go to Apple menu > System Settings"
                )

                InstructionStep(
                    number: 2,
                    title: "Go to Sound",
                    description: "Select \"Sound\" from the sidebar"
                )

                InstructionStep(
                    number: 3,
                    title: "Select Output",
                    description: "Under \"Output\", choose your Multi-Output Device"
                )

                InstructionStep(
                    number: 4,
                    title: "Return and Re-check",
                    description: "Come back here and click \"Re-check\" to verify"
                )
            }
        }
    }

    // MARK: - Open System Settings Button

    private var openSystemSettingsButton: some View {
        Button(action: {
            viewModel.openSystemSoundSettings()
        }) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Open Sound Settings")
                        .font(.headline)
                    Text("System Settings > Sound")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Sound Settings in System Settings")
    }

    // MARK: - Alternative Method

    private var alternativeMethod: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alternative: Menu Bar Method")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text("1.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Hold Option (")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(Image(systemName: "option"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    + Text(") and click the Sound icon in your menu bar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("2.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Select your Multi-Output Device under \"Output Device\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )

            Text("Note: If you don't see a Sound icon, enable it in System Settings > Control Center.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Manual Confirmation

    private var manualConfirmation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Text("Already configured?")
                .font(Typography.bodyMedium)
                .foregroundColor(.primary)

            Text("If you've already set the Multi-Output Device as your output but the check isn't detecting it, you can manually confirm:")
                .font(Typography.caption)
                .foregroundColor(.secondary)

            Button("I've Set Up System Audio") {
                viewModel.markSystemAudioConfigured()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Manually confirm system audio is configured")
            .accessibilityHint("Use this if you've configured audio but automatic detection isn't working")
        }
    }

    // MARK: - Footer

    private var systemAudioFooter: some View {
        HStack {
            WizardBackButton()

            Spacer()

            WizardNextButton()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SystemAudioStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SystemAudioStepView()
                .environmentObject(successViewModel())
                .previewDisplayName("Success")

            SystemAudioStepView()
                .environmentObject(failureViewModel())
                .previewDisplayName("Failure")
        }
        .frame(width: 600, height: 700)
    }

    static func successViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.systemAudioStatus = .success
        return vm
    }

    static func failureViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.systemAudioStatus = .failure("Multi-Output Device is not set as the system output.")
        return vm
    }
}
#endif
