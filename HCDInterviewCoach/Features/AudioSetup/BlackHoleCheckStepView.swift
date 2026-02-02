//
//  BlackHoleCheckStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - BlackHole Detection Screen
//

import SwiftUI

/// Screen for detecting and guiding BlackHole 2ch installation
struct BlackHoleCheckStepView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: AudioSetupViewModel

    // MARK: - State

    @State private var showInstallInstructions = false
    @State private var downloadButtonHovered = false

    // MARK: - Body

    var body: some View {
        WizardStepView(
            step: .blackHoleCheck,
            title: "BlackHole Virtual Audio",
            subtitle: "Required for capturing system audio",
            iconName: "waveform.path.ecg",
            iconColor: .blue
        ) {
            blackHoleContent
        } footer: {
            blackHoleFooter
        }
        .onAppear {
            // Auto-check on appear
            if viewModel.blackHoleStatus == .pending {
                viewModel.checkBlackHole()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var blackHoleContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Status section
            statusSection

            // Content based on status
            switch viewModel.blackHoleStatus {
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

            SetupStatusBadge(status: viewModel.blackHoleStatus)

            Spacer()

            if viewModel.blackHoleStatus != .checking {
                Button("Re-check") {
                    viewModel.checkBlackHole()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isChecking)
                .accessibilityLabel("Check for BlackHole again")
            }
        }
    }

    // MARK: - Checking Section

    private var checkingSection: some View {
        VStack(alignment: .center, spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Checking for BlackHole 2ch...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checking for BlackHole virtual audio device")
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .tip,
                title: "BlackHole 2ch Detected",
                message: "Great! BlackHole virtual audio device is installed and ready to use."
            )

            // What is BlackHole explanation
            explanationSection
        }
    }

    // MARK: - Failure Section

    private func failureSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Error message
            WizardInfoBox(
                style: .error,
                title: "BlackHole Not Found",
                message: message
            )

            // Installation instructions
            installationInstructions

            // Download button
            downloadSection
        }
    }

    // MARK: - Skipped Section

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .warning,
                title: "Step Skipped",
                message: "You've chosen to skip BlackHole detection. System audio capture may not work correctly without BlackHole installed."
            )

            Button("Install BlackHole Anyway") {
                viewModel.blackHoleStatus = .pending
                showInstallInstructions = true
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What is BlackHole?")
                .font(.headline)
                .foregroundColor(.primary)

            Text("BlackHole is a free, open-source virtual audio driver that creates a \"loopback\" device. It allows applications like HCD Interview Coach to capture audio that's playing on your Mac, such as your participant's voice during a video call.")
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Installation Instructions

    private var installationInstructions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installation Steps")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(
                    number: 1,
                    title: "Download BlackHole 2ch",
                    description: "Click the download button below to get BlackHole"
                )

                InstructionStep(
                    number: 2,
                    title: "Run the Installer",
                    description: "Open the downloaded .pkg file and follow the installation prompts"
                )

                InstructionStep(
                    number: 3,
                    title: "Restart Audio (if needed)",
                    description: "You may need to restart your Mac for changes to take effect"
                )

                InstructionStep(
                    number: 4,
                    title: "Return and Re-check",
                    description: "Click the Re-check button above to verify installation"
                )
            }
        }
    }

    // MARK: - Download Section

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                viewModel.openBlackHoleDownload()
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("Download BlackHole 2ch")
                            .font(.headline)
                        Text("existential.audio/blackhole")
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
                        .fill(Color.accentColor.opacity(downloadButtonHovered ? 0.15 : 0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    downloadButtonHovered = hovering
                }
            }
            .accessibilityLabel("Download BlackHole 2ch from existential audio website")
            .accessibilityHint("Opens in your default web browser")

            Text("BlackHole is free and open-source software developed by Existential Audio.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Footer

    private var blackHoleFooter: some View {
        HStack {
            WizardBackButton()

            Spacer()

            // Skip option for advanced users
            if case .failure = viewModel.blackHoleStatus {
                WizardSkipButton {
                    viewModel.skipBlackHoleCheck()
                }
            }

            WizardNextButton()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BlackHoleCheckStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Success state
            BlackHoleCheckStepView()
                .environmentObject(successViewModel())
                .previewDisplayName("Success")

            // Failure state
            BlackHoleCheckStepView()
                .environmentObject(failureViewModel())
                .previewDisplayName("Failure")
        }
        .frame(width: 600, height: 600)
    }

    static func successViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.blackHoleStatus = .success
        return vm
    }

    static func failureViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.blackHoleStatus = .failure("BlackHole 2ch is not installed.")
        return vm
    }
}
#endif
