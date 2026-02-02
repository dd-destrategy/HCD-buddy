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

    // MARK: - State

    @StateObject private var viewModel = AudioSetupViewModel()

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            // Current step content
            currentStepView

            // Keyboard shortcut hints (for accessibility)
            keyboardHints
        }
        .frame(minWidth: 620, idealWidth: 700, minHeight: 550, idealHeight: 650)
        .background(Color(NSColor.windowBackgroundColor))
        .environmentObject(viewModel)
        .keyboardNavigable(
            onEscape: { dismissWizard() }
        )
        .onKeyPress(.leftArrow, modifiers: .command) { _ in
            if viewModel.canGoBack {
                viewModel.previousStep()
            }
            return .handled
        }
        .onKeyPress(.rightArrow, modifiers: .command) { _ in
            if viewModel.canProceed {
                viewModel.nextStep()
            }
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Audio Setup Wizard")
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            // Progress track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * viewModel.currentStep.progressPercentage, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }
            }
            .frame(height: 4)

            // Step indicators
            HStack {
                ForEach(AudioSetupStep.allCases) { step in
                    stepIndicator(for: step)
                    if step != AudioSetupStep.allCases.last {
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(NSColor.windowBackgroundColor))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Step \(viewModel.currentStepNumber) of \(viewModel.totalSteps), \(viewModel.currentStep.title)")
    }

    @ViewBuilder
    private func stepIndicator(for step: AudioSetupStep) -> some View {
        let isCurrent = step == viewModel.currentStep
        let isComplete = step.rawValue < viewModel.currentStep.rawValue
        let isAccessible = step.rawValue <= viewModel.currentStep.rawValue

        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(indicatorColor(isCurrent: isCurrent, isComplete: isComplete))
                    .frame(width: 24, height: 24)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isCurrent ? .white : .secondary)
                }
            }

            Text(step.title)
                .font(.system(size: 9))
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

    private func indicatorColor(isCurrent: Bool, isComplete: Bool) -> Color {
        if isComplete {
            return .green
        } else if isCurrent {
            return .accentColor
        } else {
            return Color.gray.opacity(0.3)
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
        HStack(spacing: 16) {
            keyboardHint(key: "Esc", action: "Close")
            keyboardHint(key: "Return", action: "Continue")
            if viewModel.canGoBack {
                keyboardHint(key: "Cmd+Left", action: "Back")
            }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .accessibilityHidden(true)
    }

    private func keyboardHint(key: String, action: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                )
            Text(action)
        }
    }

    // MARK: - Actions

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
        onComplete: @escaping () -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            AudioSetupWizardView(
                isPresented: isPresented,
                onComplete: onComplete
            )
        }
    }
}

// MARK: - Launch Helper

/// Helper to determine if audio setup should be shown on app launch
struct AudioSetupLaunchHelper {

    /// Checks if the audio setup wizard should be presented on app launch
    /// Returns true if setup has never been completed or if audio devices have changed
    static func shouldPresentOnLaunch() -> Bool {
        // Check if setup has been completed
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hcd_audio_setup_completed")

        if !hasCompletedSetup {
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

    /// Resets the setup completion flag (useful for testing or re-running setup)
    static func resetSetupCompletion() {
        UserDefaults.standard.removeObject(forKey: "hcd_audio_setup_completed")
        UserDefaults.standard.removeObject(forKey: "hcd_audio_setup_completed_date")
    }
}
