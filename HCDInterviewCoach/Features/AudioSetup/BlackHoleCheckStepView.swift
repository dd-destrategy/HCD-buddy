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
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Status section
            statusSection

            // Inline tip for the most common issue
            if case .failure = viewModel.blackHoleStatus {
                InlineTroubleshootingTip(
                    message: "Not detected? Try: brew install blackhole-2ch, then restart your Mac."
                )
            }

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

            // Video tutorial link
            VideoTutorialLink(
                title: "Watch: Installing BlackHole on macOS",
                url: "https://hcdcoach.app/tutorials/blackhole-setup"
            )

            // Collapsible troubleshooting section
            if case .failure = viewModel.blackHoleStatus {
                blackHoleTroubleshootingSection
            }
        }
    }

    // MARK: - Troubleshooting

    private var blackHoleTroubleshootingSection: some View {
        TroubleshootingSection(tips: [
            .init(text: "Run \"brew install blackhole-2ch\" in Terminal if you have Homebrew installed."),
            .init(text: "If you installed manually, restart your Mac for the audio driver to register."),
            .init(text: "Check System Information > Software > Audio to confirm the driver loaded."),
            .init(text: "On macOS 13+, you may need to allow the system extension in System Settings > Privacy & Security."),
            .init(text: "Make sure you installed BlackHole 2ch (not 16ch or 64ch).")
        ])
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack {
            Text("Status:")
                .font(Typography.heading3)
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
        VStack(alignment: .center, spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Checking for BlackHole 2ch...")
                .font(Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
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
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Structured error view (if available)
            if let setupError = viewModel.currentSetupError {
                SetupErrorView(
                    error: setupError,
                    onRetry: { viewModel.checkBlackHole() },
                    onAction: { viewModel.openBlackHoleDownload() },
                    actionLabel: "Download BlackHole 2ch",
                    actionIcon: "arrow.down.circle.fill"
                )
            } else {
                // Fallback for legacy error messages
                WizardInfoBox(
                    style: .error,
                    title: "BlackHole Not Found",
                    message: message
                )
            }

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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("What is BlackHole?")
                .font(Typography.heading3)
                .foregroundColor(.primary)

            Text("BlackHole is a free, open-source virtual audio driver that creates a \"loopback\" device. It allows applications like HCD Interview Coach to capture audio that's playing on your Mac, such as your participant's voice during a video call.")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Installation Instructions

    private var installationInstructions: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Installation Steps")
                .font(Typography.heading3)
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

            // "I already have this configured" shortcut for experienced users
            if viewModel.blackHoleStatus != .success {
                Button(action: {
                    viewModel.markBlackHoleAlreadyConfigured()
                }) {
                    Text("I already have this configured")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark BlackHole as already configured")
                .accessibilityHint("For experienced users who have already installed BlackHole")
            }

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
