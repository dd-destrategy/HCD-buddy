//
//  VerificationStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Audio Verification Screen
//

import SwiftUI

/// Screen for testing and verifying audio capture works correctly
struct VerificationStepView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: AudioSetupViewModel

    // MARK: - State

    @State private var showTroubleshooting = false
    @State private var testDuration: TimeInterval = 0
    @State private var testTimer: Timer?

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        WizardStepView(
            step: .verification,
            title: "Audio Verification",
            subtitle: "Test that audio capture is working correctly",
            iconName: "checkmark.seal.fill",
            iconColor: .green
        ) {
            verificationContent
        } footer: {
            verificationFooter
        }
        .onDisappear {
            viewModel.stopTestAudio()
            testTimer?.invalidate()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var verificationContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Status section
            statusSection

            // Content based on status
            switch viewModel.verificationStatus {
            case .pending:
                pendingSection
            case .checking:
                testingSection
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

            SetupStatusBadge(status: viewModel.verificationStatus)

            Spacer()
        }
    }

    // MARK: - Pending Section

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            WizardInfoBox(
                style: .info,
                title: "Ready to Test",
                message: "We'll play a test sound and verify that the app can capture it through BlackHole. Make sure your volume is at a comfortable level."
            )

            // Test instructions
            testInstructions

            // Start test button
            startTestButton
        }
    }

    // MARK: - Testing Section

    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Test in progress indicator
            testProgressSection

            // Audio level meters
            audioLevelMeters

            // Audio detection status
            audioDetectionStatus

            // Controls
            testControls
        }
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            WizardInfoBox(
                style: .tip,
                title: "Audio Capture Verified",
                message: "System audio is being captured successfully. Your setup is complete and ready for interviews!"
            )

            // What was verified
            verificationSummary
        }
    }

    // MARK: - Failure Section

    private func failureSection(message: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            WizardInfoBox(
                style: .error,
                title: "Verification Failed",
                message: message
            )

            // Troubleshooting section
            troubleshootingSection

            // Retry button
            Button("Try Again") {
                viewModel.verificationStatus = .pending
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Skipped Section

    private var skippedSection: some View {
        WizardInfoBox(
            style: .warning,
            title: "Verification Skipped",
            message: "Audio capture was not verified. You may encounter issues during interviews if the setup isn't correct."
        )
    }

    // MARK: - Test Instructions

    private var testInstructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What happens during the test:")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                instructionItem(
                    number: 1,
                    text: "A test sound will play through your speakers"
                )
                instructionItem(
                    number: 2,
                    text: "The app will try to capture it through BlackHole"
                )
                instructionItem(
                    number: 3,
                    text: "Audio levels will display if capture is working"
                )
            }
        }
    }

    private func instructionItem(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                .frame(width: 20, alignment: .trailing)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Start Test Button

    private var startTestButton: some View {
        Button(action: startTest) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Audio Test")
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityLabel("Start audio verification test")
        .accessibilityHint("Plays a test sound to verify audio capture")
    }

    // MARK: - Test Progress Section

    private var testProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Testing Audio Capture...")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(String(format: "%.1fs", testDuration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ProgressView()
                .progressViewStyle(.linear)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
        )
    }

    // MARK: - Audio Level Meters

    private var audioLevelMeters: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio Levels")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                // System audio level
                audioLevelMeter(
                    label: "System Audio (BlackHole)",
                    level: viewModel.systemAudioLevel,
                    color: .blue
                )

                // Microphone level
                audioLevelMeter(
                    label: "Microphone",
                    level: viewModel.microphoneAudioLevel,
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private func audioLevelMeter(label: String, level: Float, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(level * 100))%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // Level indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(levelColor(for: level, baseColor: color))
                        .frame(width: geometry.size.width * CGFloat(level))
                        .animation(reduceMotion ? nil : .easeOut(duration: AnimationTiming.veryFast), value: level)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) level")
        .accessibilityValue("\(Int(level * 100)) percent")
    }

    private func levelColor(for level: Float, baseColor: Color) -> Color {
        if level > 0.8 {
            return .red
        } else if level > 0.6 {
            return .orange
        } else {
            return baseColor
        }
    }

    // MARK: - Audio Detection Status

    private var audioDetectionStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.audioDetected ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title2)
                .foregroundColor(viewModel.audioDetected ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.audioDetected ? "Audio Detected" : "Waiting for audio...")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.audioDetected ? .green : .primary)

                Text(viewModel.audioDetected ?
                     "System audio is being captured successfully" :
                     "Play some audio or speak into your microphone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(viewModel.audioDetected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.audioDetected ? "Audio detected and being captured" : "Waiting for audio detection")
    }

    // MARK: - Test Controls

    private var testControls: some View {
        HStack(spacing: 12) {
            // Stop test
            Button(action: {
                viewModel.stopTestAudio()
                viewModel.verificationStatus = .pending
                testTimer?.invalidate()
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Test")
                }
            }
            .buttonStyle(.bordered)

            Spacer()

            // Confirm success (if audio detected)
            if viewModel.audioDetected {
                Button(action: {
                    viewModel.confirmVerification()
                    testTimer?.invalidate()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Audio Works!")
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            // Report failure
            Button(action: {
                viewModel.failVerification(reason: "Audio was not detected during the test. Please check your setup and try again.")
                testTimer?.invalidate()
            }) {
                Text("I Don't Hear Audio")
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
    }

    // MARK: - Verification Summary

    private var verificationSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verified Components")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                verifiedItem("BlackHole 2ch is installed")
                verifiedItem("Multi-Output Device is configured")
                verifiedItem("System audio output is set correctly")
                verifiedItem("Audio capture is working")
            }
        }
    }

    private func verifiedItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Troubleshooting Section

    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                if reduceMotion {
                    showTroubleshooting.toggle()
                } else {
                    withAnimation(.easeInOut(duration: AnimationTiming.normal)) {
                        showTroubleshooting.toggle()
                    }
                }
            }) {
                HStack {
                    Text("Troubleshooting Tips")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showTroubleshooting ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.primary)

            if showTroubleshooting {
                VStack(alignment: .leading, spacing: 8) {
                    troubleshootingTip("Ensure your volume isn't muted")
                    troubleshootingTip("Check that Multi-Output Device is selected as system output")
                    troubleshootingTip("Verify BlackHole is included in your Multi-Output Device")
                    troubleshootingTip("Try restarting Audio MIDI Setup")
                    troubleshootingTip("Some apps may bypass system audio - try playing from a different app")
                }

                Button("Open Troubleshooting Guide") {
                    viewModel.openTroubleshootingGuide()
                }
                .buttonStyle(.link)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
    }

    private func troubleshootingTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.orange)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Footer

    private var verificationFooter: some View {
        HStack {
            WizardBackButton()

            Spacer()

            WizardNextButton()
        }
    }

    // MARK: - Actions

    private func startTest() {
        testDuration = 0
        viewModel.startTestAudio()

        // Start timer for duration display
        testTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                testDuration += 0.1
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct VerificationStepView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VerificationStepView()
                .environmentObject(pendingViewModel())
                .previewDisplayName("Pending")

            VerificationStepView()
                .environmentObject(testingViewModel())
                .previewDisplayName("Testing")

            VerificationStepView()
                .environmentObject(successViewModel())
                .previewDisplayName("Success")
        }
        .frame(width: 600, height: 650)
    }

    static func pendingViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.verificationStatus = .pending
        return vm
    }

    static func testingViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.verificationStatus = .checking
        vm.systemAudioLevel = 0.6
        vm.microphoneAudioLevel = 0.2
        vm.audioDetected = true
        return vm
    }

    static func successViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.verificationStatus = .success
        return vm
    }
}
#endif
