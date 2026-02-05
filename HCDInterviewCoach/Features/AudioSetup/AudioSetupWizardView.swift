//
//  AudioSetupWizardView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Main Container View
//

import SwiftUI

/// Main container view for the Audio Setup Wizard
/// Manages step navigation and provides consistent chrome around step content
struct AudioSetupWizardView: View {

    // MARK: - Properties

    @Binding var isPresented: Bool
    var onComplete: () -> Void
    var onSkipSetup: (() -> Void)?

    // MARK: - State

    @StateObject private var viewModel = AudioSetupViewModel()

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            // Current step content
            currentStepView

            // Skip setup link (shown on non-complete steps)
            if viewModel.currentStep != .complete {
                skipSetupLink
            }

            // Keyboard shortcut hints (for accessibility)
            keyboardHints
        }
        .frame(minWidth: 620, idealWidth: 700, minHeight: 550, idealHeight: 650)
        .background(wizardBackground)
        .glassSheet()
        .environmentObject(viewModel)
        .keyboardNavigable(
            onEscape: { dismissWizard() }
        )
        .onKeyPress(.leftArrow) {
            if viewModel.canGoBack {
                viewModel.previousStep()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.rightArrow) {
            if viewModel.canProceed {
                viewModel.nextStep()
                return .handled
            }
            return .ignored
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Audio Setup Wizard")
    }

    // MARK: - Wizard Background

    private var wizardBackground: some View {
        ZStack {
            // Gradient backdrop for glass effect visibility
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(white: 0.08), Color(white: 0.12)]
                    : [Color(white: 0.94), Color(white: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle accent color wash
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(colorScheme == .dark ? 0.08 : 0.05),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: Spacing.sm) {
            // Progress track with glass styling
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track - glass effect
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                    lineWidth: 0.5
                                )
                        )
                        .frame(height: 6)

                    // Progress fill with glow
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.currentStep.progressPercentage, height: 6)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 4, x: 0, y: 0)
                        .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: viewModel.currentStep)
                }
            }
            .frame(height: 6)

            // Step indicators with glass styling
            HStack {
                ForEach(AudioSetupStep.allCases) { step in
                    stepIndicator(for: step)
                    if step != AudioSetupStep.allCases.last {
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Step \(viewModel.currentStepNumber) of \(viewModel.totalSteps), \(viewModel.currentStep.title)")
    }

    @ViewBuilder
    private func stepIndicator(for step: AudioSetupStep) -> some View {
        let isCurrent = step == viewModel.currentStep
        let isComplete = step.rawValue < viewModel.currentStep.rawValue
        let isAccessible = step.rawValue <= viewModel.currentStep.rawValue

        VStack(spacing: Spacing.xs) {
            ZStack {
                // Glass circle background
                Circle()
                    .fill(indicatorMaterial(isCurrent: isCurrent, isComplete: isComplete))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(
                                indicatorBorderGradient(isCurrent: isCurrent, isComplete: isComplete),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: indicatorShadowColor(isCurrent: isCurrent, isComplete: isComplete),
                        radius: isCurrent ? 6 : 3,
                        x: 0,
                        y: 2
                    )

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isCurrent ? .white : .secondary)
                }
            }

            Text(step.title)
                .font(Typography.small)
                .foregroundColor(isCurrent ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(width: 70)
        .opacity(isAccessible ? 1.0 : 0.5)
        .onTapGesture {
            // Allow clicking completed steps to go back
            if isComplete {
                viewModel.goToStep(step)
            }
        }
    }

    private func indicatorMaterial(isCurrent: Bool, isComplete: Bool) -> some ShapeStyle {
        if isComplete {
            return AnyShapeStyle(Color.green)
        } else if isCurrent {
            return AnyShapeStyle(Color.accentColor)
        } else {
            return AnyShapeStyle(Material.ultraThinMaterial)
        }
    }

    private func indicatorBorderGradient(isCurrent: Bool, isComplete: Bool) -> LinearGradient {
        if isComplete {
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isCurrent {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func indicatorShadowColor(isCurrent: Bool, isComplete: Bool) -> Color {
        if isComplete {
            return Color.green.opacity(0.3)
        } else if isCurrent {
            return Color.accentColor.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }

    // MARK: - Current Step View

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .blackHoleCheck:
            BlackHoleCheckStepView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .multiOutputSetup:
            MultiOutputSetupStepView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .systemAudioSelection:
            SystemAudioStepView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .verification:
            VerificationStepView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .complete:
            CompleteStepView(
                isPresented: $isPresented,
                onComplete: onComplete
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Keyboard Hints

    private var keyboardHints: some View {
        HStack(spacing: Spacing.lg) {
            keyboardHint(key: "Esc", action: "Close")
            keyboardHint(key: "Return", action: "Continue")
            if viewModel.canGoBack {
                keyboardHint(key: "Cmd+Left", action: "Back")
            }
        }
        .font(Typography.small)
        .foregroundColor(.secondary)
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
        .accessibilityHidden(true)
    }

    private func keyboardHint(key: String, action: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(key)
                .font(Typography.small)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.small)
                                .stroke(
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                    lineWidth: 0.5
                                )
                        )
                )
            Text(action)
        }
    }

    // MARK: - Skip Setup Link

    private var skipSetupLink: some View {
        Button(action: {
            skipEntireSetup()
        }) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(Typography.caption)
                Text("I\u{2019}ll set this up later")
                    .font(Typography.caption)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .accessibilityLabel("Skip audio setup")
        .accessibilityHint("Launches the app in limited mode without full audio capture. You can complete setup later from Settings.")
    }

    // MARK: - Actions

    private func skipEntireSetup() {
        viewModel.skipEntireSetup()
        onSkipSetup?()
        isPresented = false
    }

    private func dismissWizard() {
        if viewModel.currentStep == .complete {
            onComplete()
        }
        isPresented = false
    }
}

// MARK: - Keyboard Shortcut Extension

extension AudioSetupWizardView {

    /// Handles keyboard navigation within the wizard
    func handleKeyPress(_ key: KeyEquivalent, modifiers: EventModifiers = []) -> KeyPress.Result {
        switch key {
        case .escape:
            dismissWizard()
            return .handled

        case .return:
            if viewModel.canProceed {
                viewModel.nextStep()
            }
            return .handled

        case .leftArrow where modifiers.contains(.command):
            if viewModel.canGoBack {
                viewModel.previousStep()
            }
            return .handled

        case .rightArrow where modifiers.contains(.command):
            if viewModel.canProceed {
                viewModel.nextStep()
            }
            return .handled

        default:
            return .ignored
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AudioSetupWizardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AudioSetupWizardView(
                isPresented: .constant(true),
                onComplete: {}
            )
            .previewDisplayName("Welcome Step")

            AudioSetupWizardView(
                isPresented: .constant(true),
                onComplete: {}
            )
            .onAppear {
                // Note: This won't work in preview but shows intent
            }
            .previewDisplayName("BlackHole Step")
        }
    }
}
#endif

// MARK: - Sheet Presentation Modifier

extension View {

    /// Presents the Audio Setup Wizard as a sheet
    func audioSetupSheet(
        isPresented: Binding<Bool>,
        onComplete: @escaping () -> Void,
        onSkipSetup: (() -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            AudioSetupWizardView(
                isPresented: isPresented,
                onComplete: onComplete,
                onSkipSetup: onSkipSetup
            )
        }
    }
}

// MARK: - Launch Helper

/// Helper to determine if audio setup should be shown on app launch
struct AudioSetupLaunchHelper {

    /// Checks if the audio setup wizard should be presented on app launch
    /// Returns true if setup has never been completed or skipped, or if audio devices have changed
    static func shouldPresentOnLaunch() -> Bool {
        // Check if setup has been completed
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hcd_audio_setup_completed")

        if !hasCompletedSetup {
            // If setup was skipped, don't present the wizard again automatically
            let wasSkipped = UserDefaults.standard.bool(forKey: "hcd_audio_setup_skipped")
            if wasSkipped {
                return false
            }
            return true
        }

        // Validate current audio setup
        let blackHoleStatus = BlackHoleDetector.detectBlackHole()
        let multiOutputStatus = MultiOutputDetector.detectMultiOutputDevice()

        // If BlackHole is no longer installed, prompt setup
        if case .notInstalled = blackHoleStatus {
            return true
        }

        // If Multi-Output is no longer configured, prompt setup
        if case .notFound = multiOutputStatus {
            return true
        }

        return false
    }

    /// Whether the audio setup was skipped (app is in limited mode)
    static var isAudioSetupSkipped: Bool {
        let wasSkipped = UserDefaults.standard.bool(forKey: "hcd_audio_setup_skipped")
        let hasCompleted = UserDefaults.standard.bool(forKey: "hcd_audio_setup_completed")
        return wasSkipped && !hasCompleted
    }

    /// Resets the setup completion flag (useful for testing or re-running setup)
    static func resetSetupCompletion() {
        UserDefaults.standard.removeObject(forKey: "hcd_audio_setup_completed")
        UserDefaults.standard.removeObject(forKey: "hcd_audio_setup_completed_date")
    }

    /// Clears the skip state so the wizard will be presented again
    static func clearSkipState() {
        UserDefaults.standard.removeObject(forKey: "hcd_audio_setup_skipped")
        UserDefaults.standard.removeObject(forKey: "hcd_audio_setup_skipped_date")
    }
}
