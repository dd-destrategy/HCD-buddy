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
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Introduction text with glass card
            introductionSection
                .padding(Spacing.lg)
                .glassCard()

            // What we'll set up
            setupOverviewSection

            // Requirements with glass styling
            requirementsSection
                .padding(Spacing.lg)
                .liquidGlass(
                    material: .thin,
                    cornerRadius: CornerRadius.large,
                    borderStyle: .subtle,
                    enableHover: false
                )

            // Time estimate
            timeEstimateSection
        }
    }

    private var introductionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(Typography.heading2)
                    .foregroundColor(.accentColor)
                Text("Welcome to HCD Interview Coach")
                    .font(Typography.heading2)
                    .foregroundColor(.primary)
            }

            Text("To provide real-time coaching during your interviews, this app needs to capture both system audio (your participant's voice) and your microphone. This requires a one-time audio configuration.")
                .font(Typography.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var setupOverviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("What We'll Set Up")
                .font(Typography.heading3)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: Spacing.md) {
                setupItem(
                    icon: "speaker.wave.2.fill",
                    title: "BlackHole Virtual Audio",
                    description: "A free audio driver that routes system sound",
                    color: .blue,
                    stepNumber: 1
                )

                setupItem(
                    icon: "rectangle.stack.fill",
                    title: "Multi-Output Device",
                    description: "Combines your speakers with BlackHole",
                    color: .purple,
                    stepNumber: 2
                )

                setupItem(
                    icon: "checkmark.seal.fill",
                    title: "Audio Verification",
                    description: "Confirms everything works correctly",
                    color: .green,
                    stepNumber: 3
                )
            }
        }
    }

    private func setupItem(icon: String, title: String, description: String, color: Color, stepNumber: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // Glass icon container with glow
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.5),
                                        color.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: color.opacity(0.2), radius: 6, x: 0, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(animateIcons ? 1.0 : 0.8)
                    .opacity(animateIcons ? 1.0 : 0.6)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)

                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Step number badge
            Text("\(stepNumber)")
                .font(Typography.small)
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 0.5)
                        )
                )
        }
        .padding(Spacing.md)
        .liquidGlass(
            material: .thin,
            cornerRadius: CornerRadius.large,
            borderStyle: .subtle,
            enableHover: true,
            enablePress: false
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checklist")
                    .font(Typography.heading3)
                    .foregroundColor(.secondary)
                Text("Requirements")
                    .font(Typography.heading3)
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
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
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isMet ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 20, height: 20)

                Image(systemName: isMet ? "checkmark" : "circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isMet ? .green : .secondary)
            }
            .accessibilityHidden(true)

            Text(text)
                .font(Typography.body)
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
