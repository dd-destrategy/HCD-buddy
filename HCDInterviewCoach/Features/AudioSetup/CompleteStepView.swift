//
//  CompleteStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Success/Completion Screen
//

import SwiftUI

/// Final screen showing setup completion and next steps
struct CompleteStepView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: AudioSetupViewModel
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    // MARK: - State

    @State private var showConfetti = false
    @State private var animateCheckmark = false

    // MARK: - Body

    var body: some View {
        WizardStepView(
            step: .complete,
            title: "Setup Complete!",
            subtitle: "Your audio is configured and ready for interviews",
            iconName: "checkmark.circle.fill",
            iconColor: .green
        ) {
            completeContent
        } footer: {
            completeFooter
        }
        .onAppear {
            // Trigger animations
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                animateCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showConfetti = true
            }

            // Mark setup as complete
            viewModel.completeSetup()
        }
    }

    // MARK: - Content

    private var completeContent: some View {
        VStack(alignment: .center, spacing: 32) {
            // Success animation
            successAnimation

            // Summary of what was set up
            setupSummary

            Divider()

            // Next steps
            nextStepsSection

            // Quick reference
            quickReferenceSection
        }
    }

    // MARK: - Success Animation

    private var successAnimation: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circles
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                    .opacity(animateCheckmark ? 1.0 : 0.0)

                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                    .opacity(animateCheckmark ? 1.0 : 0.0)

                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                    .opacity(animateCheckmark ? 1.0 : 0.0)
            }
            .accessibilityHidden(true)

            Text("Audio Setup Complete")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("You're ready to start coaching interviews!")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Success! Audio setup is complete. You're ready to start coaching interviews.")
    }

    // MARK: - Setup Summary

    private var setupSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What Was Configured")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                summaryItem(
                    icon: "waveform.circle.fill",
                    title: "BlackHole",
                    status: statusText(for: viewModel.blackHoleStatus),
                    color: statusColor(for: viewModel.blackHoleStatus)
                )

                summaryItem(
                    icon: "rectangle.stack.fill",
                    title: "Multi-Output",
                    status: statusText(for: viewModel.multiOutputStatus),
                    color: statusColor(for: viewModel.multiOutputStatus)
                )

                summaryItem(
                    icon: "speaker.wave.3.fill",
                    title: "System Audio",
                    status: statusText(for: viewModel.systemAudioStatus),
                    color: statusColor(for: viewModel.systemAudioStatus)
                )

                summaryItem(
                    icon: "checkmark.seal.fill",
                    title: "Verified",
                    status: statusText(for: viewModel.verificationStatus),
                    color: statusColor(for: viewModel.verificationStatus)
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func summaryItem(icon: String, title: String, status: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text(status)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(status)")
    }

    private func statusText(for status: AudioSetupStatus) -> String {
        switch status {
        case .success:
            return "Ready"
        case .skipped:
            return "Skipped"
        case .failure:
            return "Issue"
        default:
            return "Pending"
        }
    }

    private func statusColor(for status: AudioSetupStatus) -> Color {
        switch status {
        case .success:
            return .green
        case .skipped:
            return .orange
        case .failure:
            return .red
        default:
            return .gray
        }
    }

    // MARK: - Next Steps Section

    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Next")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 10) {
                nextStepItem(
                    number: 1,
                    title: "Start an Interview",
                    description: "Open a video call and click \"Start Session\" to begin coaching"
                )

                nextStepItem(
                    number: 2,
                    title: "Real-Time Feedback",
                    description: "Get AI-powered coaching suggestions during your interviews"
                )

                nextStepItem(
                    number: 3,
                    title: "Review Insights",
                    description: "After each session, review captured insights and themes"
                )
            }
        }
    }

    private func nextStepItem(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description)")
    }

    // MARK: - Quick Reference Section

    private var quickReferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Reference")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                referenceItem(
                    icon: "speaker.wave.2.fill",
                    text: "Before each interview, check that Multi-Output Device is selected"
                )

                referenceItem(
                    icon: "questionmark.circle.fill",
                    text: "Having issues? Access troubleshooting from Settings > Audio"
                )

                referenceItem(
                    icon: "arrow.clockwise.circle.fill",
                    text: "Run setup again anytime from Settings > Audio > Re-run Setup"
                )
            }

            // Troubleshooting link
            Button(action: {
                viewModel.openTroubleshootingGuide()
            }) {
                HStack {
                    Image(systemName: "book.fill")
                    Text("View Audio Troubleshooting Guide")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .font(.subheadline)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            .accessibilityLabel("Open audio troubleshooting guide in browser")
        }
    }

    private func referenceItem(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer

    private var completeFooter: some View {
        HStack {
            // Run setup again option
            Button("Run Setup Again") {
                viewModel.resetSetup()
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Reset and run audio setup again")

            Spacer()

            // Done button
            Button(action: {
                onComplete()
                isPresented = false
            }) {
                HStack {
                    Text("Done")
                    Image(systemName: "arrow.right")
                }
                .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
            .accessibilityLabel("Finish setup and close wizard")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CompleteStepView_Previews: PreviewProvider {
    static var previews: some View {
        CompleteStepView(
            isPresented: .constant(true),
            onComplete: {}
        )
        .environmentObject(completeViewModel())
        .frame(width: 600, height: 700)
    }

    static func completeViewModel() -> AudioSetupViewModel {
        let vm = AudioSetupViewModel()
        vm.currentStep = .complete
        vm.blackHoleStatus = .success
        vm.multiOutputStatus = .success
        vm.systemAudioStatus = .success
        vm.verificationStatus = .success
        return vm
    }
}
#endif
