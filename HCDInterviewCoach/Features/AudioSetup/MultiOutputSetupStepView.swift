//
//  MultiOutputSetupStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Multi-Output Device Setup Screen
//

import SwiftUI

/// Screen guiding users through Multi-Output Device creation
struct MultiOutputSetupStepView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: AudioSetupViewModel

    // MARK: - State

    @State private var currentInstructionStep: Int = 0
    @State private var showDetailedInstructions = true

    // MARK: - Body

    var body: some View {
        WizardStepView(
            step: .multiOutputSetup,
            title: "Multi-Output Device",
            subtitle: "Route audio to speakers and BlackHole simultaneously",
            iconName: "rectangle.stack.badge.plus",
            iconColor: .purple
        ) {
            multiOutputContent
        } footer: {
            multiOutputFooter
        }
        .onAppear {
            if viewModel.multiOutputStatus == .pending {
                viewModel.checkMultiOutput()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var multiOutputContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Status section
            statusSection

            // Content based on status
            switch viewModel.multiOutputStatus {
            case .pending, .checking:
                checkingSection
            case .success:
                successSection
            case .failure(let message):
                failureSection(message: message)
            case .skipped:
                skippedSection
            }
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack {
            Text("Status:")
                .font(.headline)
                .foregroundColor(.primary)

            SetupStatusBadge(status: viewModel.multiOutputStatus)

            Spacer()

            if viewModel.multiOutputStatus != .checking {
                Button("Re-check") {
                    viewModel.checkMultiOutput()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isChecking)
                .accessibilityLabel("Check for Multi-Output Device again")
            }
        }
    }

    // MARK: - Checking Section

    private var checkingSection: some View {
        VStack(alignment: .center, spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Checking for Multi-Output Device...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .tip,
                title: "Multi-Output Device Configured",
                message: "Your Multi-Output Device is properly set up with BlackHole and your speakers."
            )

            explanationSection
        }
    }

    // MARK: - Failure Section

    private func failureSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Error message
            WizardInfoBox(
                style: .error,
                title: "Multi-Output Device Not Found",
                message: message
            )

            // Open Audio MIDI Setup button
            openAudioMIDIButton

            Divider()

            // Detailed instructions
            if showDetailedInstructions {
                setupInstructions
            }

            // Toggle detailed instructions
            Button(action: {
                withAnimation {
                    showDetailedInstructions.toggle()
                }
            }) {
                HStack {
                    Text(showDetailedInstructions ? "Hide Instructions" : "Show Instructions")
                    Image(systemName: showDetailedInstructions ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Skipped Section

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .warning,
                title: "Step Skipped",
                message: "Without a Multi-Output Device, you won't hear audio while the app captures it. This is not recommended."
            )

            Button("Configure Multi-Output Device") {
                viewModel.multiOutputStatus = .pending
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why Multi-Output Device?")
                .font(.headline)
                .foregroundColor(.primary)

            Text("A Multi-Output Device sends audio to multiple destinations at once. This lets you hear your participant through your speakers while BlackHole simultaneously captures the audio for analysis.")
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Open Audio MIDI Setup Button

    private var openAudioMIDIButton: some View {
        Button(action: {
            viewModel.openAudioMIDISetup()
        }) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Open Audio MIDI Setup")
                        .font(.headline)
                    Text("Configure audio devices")
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
                    .fill(Color.purple.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Audio MIDI Setup application")
        .accessibilityHint("Opens the macOS Audio MIDI Setup utility")
    }

    // MARK: - Setup Instructions

    private var setupInstructions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup Instructions")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 16) {
                InstructionStep(
                    number: 1,
                    title: "Open Audio MIDI Setup",
                    description: "Click the button above or find it in Applications > Utilities"
                )

                InstructionStep(
                    number: 2,
                    title: "Click the + button",
                    description: "In the bottom-left corner, click + and select \"Create Multi-Output Device\""
                )

                InstructionStep(
                    number: 3,
                    title: "Add BlackHole 2ch",
                    description: "Check the box next to \"BlackHole 2ch\" in the device list"
                )

                InstructionStep(
                    number: 4,
                    title: "Add Your Speakers",
                    description: "Also check your speakers or headphones (e.g., \"MacBook Pro Speakers\" or \"External Headphones\")"
                )

                InstructionStep(
                    number: 5,
                    title: "Set Master Device",
                    description: "Click the gear icon and set your speakers as the \"Master Device\" for best sync"
                )

                InstructionStep(
                    number: 6,
                    title: "Rename (Optional)",
                    description: "Double-click the name to rename it to something memorable like \"Interview Audio\""
                )
            }

            // Visual diagram
            multiOutputDiagram
        }
    }

    // MARK: - Multi-Output Diagram

    private var multiOutputDiagram: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How It Works")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            HStack(spacing: 0) {
                // Input
                VStack(spacing: 4) {
                    Image(systemName: "desktopcomputer")
                        .font(.title)
                    Text("System Audio")
                        .font(.caption2)
                }
                .frame(width: 80)
                .foregroundColor(.blue)

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 40)

                // Multi-Output
                VStack(spacing: 4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 100, height: 50)
                        Image(systemName: "rectangle.stack.fill")
                            .font(.title)
                            .foregroundColor(.purple)
                    }
                    Text("Multi-Output")
                        .font(.caption2)
                }
                .frame(width: 100)

                // Arrows out
                VStack(spacing: 20) {
                    Image(systemName: "arrow.right")
                    Image(systemName: "arrow.right")
                }
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 40)

                // Outputs
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title2)
                        Text("Speakers")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)

                    VStack(spacing: 4) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                        Text("BlackHole")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
                .frame(width: 80)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Diagram showing audio flow from system audio through Multi-Output Device to both speakers and BlackHole")
    }

    // MARK: - Footer

    private var multiOutputFooter: some View {
        HStack {
            WizardBackButton()

            Spacer()

            // Skip option
            if case .failure = viewModel.multiOutputStatus {
                WizardSkipButton {
                    viewModel.skipMultiOutputSetup()
                }
            }

            WizardNextButton()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MultiOutputSetupStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MultiOutputSetupStepView()
                .environmentObject(successViewModel())
                .previewDisplayName("Success")

            MultiOutputSetupStepView()
                .environmentObject(failureViewModel())
                .previewDisplayName("Failure")
        }
        .frame(width: 600, height: 700)
    }

    static func successViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.multiOutputStatus = .success
        return vm
    }

    static func failureViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.multiOutputStatus = .failure("No Multi-Output Device found.")
        return vm
    }
}
#endif
