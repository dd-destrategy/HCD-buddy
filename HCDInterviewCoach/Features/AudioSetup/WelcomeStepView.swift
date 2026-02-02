//
//  WelcomeStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Welcome Screen
//

import SwiftUI

/// Welcome screen introducing users to the audio setup process
struct WelcomeStepView: View {

    // MARK: - Environment

    @EnvironmentObject private var viewModel: AudioSetupViewModel
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var animateIcons = false

    // MARK: - Body

    var body: some View {
        WizardStepView(
            step: .welcome,
            title: "Audio Setup",
            subtitle: "Configure your Mac to capture interview audio",
            iconName: "waveform.circle.fill",
            iconColor: .accentColor
        ) {
            welcomeContent
        } footer: {
            welcomeFooter
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animateIcons = true
            }
        }
    }

    // MARK: - Content

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Introduction text
            introductionSection

            Divider()

            // What we'll set up
            setupOverviewSection

            Divider()

            // Requirements
            requirementsSection

            // Time estimate
            timeEstimateSection
        }
    }

    private var introductionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to HCD Interview Coach")
                .font(.headline)
                .foregroundColor(.primary)

            Text("To provide real-time coaching during your interviews, this app needs to capture both system audio (your participant's voice) and your microphone. This requires a one-time audio configuration.")
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var setupOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What We'll Set Up")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                setupItem(
                    icon: "speaker.wave.2.fill",
                    title: "BlackHole Virtual Audio",
                    description: "A free audio driver that routes system sound",
                    color: .blue
                )

                setupItem(
                    icon: "rectangle.stack.fill",
                    title: "Multi-Output Device",
                    description: "Combines your speakers with BlackHole",
                    color: .purple
                )

                setupItem(
                    icon: "checkmark.seal.fill",
                    title: "Audio Verification",
                    description: "Confirms everything works correctly",
                    color: .green
                )
            }
        }
    }

    private func setupItem(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .scaleEffect(animateIcons ? 1.0 : 0.8)
                    .opacity(animateIcons ? 1.0 : 0.6)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                requirementItem(
                    "macOS 11.0 or later",
                    isMet: true
                )
                requirementItem(
                    "Administrator access to install BlackHole",
                    isMet: true
                )
                requirementItem(
                    "Working speakers or headphones",
                    isMet: true
                )
                requirementItem(
                    "Microphone (built-in or external)",
                    isMet: true
                )
            }
        }
    }

    private func requirementItem(_ text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(isMet ? .green : .secondary)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text), \(isMet ? "requirement met" : "requirement not met")")
    }

    private var timeEstimateSection: some View {
        WizardInfoBox(
            style: .info,
            title: "Time Estimate",
            message: "This setup takes about 5-10 minutes. You only need to do this once."
        )
    }

    // MARK: - Footer

    private var welcomeFooter: some View {
        HStack {
            Spacer()

            WizardNextButton(title: "Get Started")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeStepView()
            .environmentObject(AudioSetupViewModel())
            .frame(width: 600, height: 600)
    }
}
#endif
