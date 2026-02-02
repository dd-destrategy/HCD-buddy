//
//  AudioSetupCoordinator.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Navigation Coordination
//

import Foundation
import SwiftUI
import Combine

/// Coordinates navigation and presentation of the Audio Setup Wizard
/// Manages the wizard lifecycle and interaction with the rest of the app
@MainActor
final class AudioSetupCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Whether the wizard is currently presented
    @Published var isWizardPresented: Bool = false

    /// The view model for the current wizard session
    @Published private(set) var viewModel: AudioSetupViewModel

    /// Navigation path for programmatic navigation
    @Published var navigationPath: [AudioSetupStep] = []

    // MARK: - Callbacks

    /// Called when the wizard is completed successfully
    var onWizardComplete: (() -> Void)?

    /// Called when the wizard is dismissed without completing
    var onWizardDismissed: (() -> Void)?

    /// Called when audio setup needs to be re-run
    var onSetupRequired: (() -> Void)?

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKeys {
        static let shouldShowSetupOnLaunch = "hcd_should_show_audio_setup_on_launch"
        static let setupPromptDismissedDate = "hcd_setup_prompt_dismissed_date"
    }

    // MARK: - Computed Properties

    /// Whether the audio setup wizard should be shown on app launch
    var shouldShowSetupOnLaunch: Bool {
        // Don't show if already completed
        if viewModel.wasSetupPreviouslyCompleted {
            return false
        }

        // Don't show if user dismissed within the last 24 hours
        if let dismissedDate = UserDefaults.standard.object(forKey: UserDefaultsKeys.setupPromptDismissedDate) as? Date {
            let hoursSinceDismissed = Date().timeIntervalSince(dismissedDate) / 3600
            if hoursSinceDismissed < 24 {
                return false
            }
        }

        // Check if setup is forced to show
        return UserDefaults.standard.bool(forKey: UserDefaultsKeys.shouldShowSetupOnLaunch)
    }

    /// Whether audio setup has been successfully completed
    var isAudioSetupComplete: Bool {
        viewModel.wasSetupPreviouslyCompleted
    }

    // MARK: - Initialization

    init() {
        self.viewModel = AudioSetupViewModel()
        setupBindings()
    }

    private func setupBindings() {
        // Listen for wizard completion
        viewModel.$currentStep
            .sink { [weak self] step in
                if step == .complete {
                    self?.handleWizardCompletion()
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Presentation

    /// Present the audio setup wizard
    func presentWizard() {
        // Reset view model for fresh start
        viewModel = AudioSetupViewModel()
        isWizardPresented = true
    }

    /// Present the wizard starting at a specific step
    func presentWizard(startingAt step: AudioSetupStep) {
        viewModel = AudioSetupViewModel()
        viewModel.goToStep(step)
        isWizardPresented = true
    }

    /// Dismiss the wizard
    func dismissWizard() {
        isWizardPresented = false

        // If wizard was dismissed before completion, record the dismissal
        if viewModel.currentStep != .complete {
            UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.setupPromptDismissedDate)
            onWizardDismissed?()
        }
    }

    /// Dismiss the wizard and mark setup as complete
    func completeAndDismiss() {
        viewModel.completeSetup()
        isWizardPresented = false
        onWizardComplete?()
    }

    // MARK: - Navigation

    /// Navigate to the next step in the wizard
    func nextStep() {
        viewModel.nextStep()
    }

    /// Navigate to the previous step in the wizard
    func previousStep() {
        viewModel.previousStep()
    }

    /// Navigate directly to a specific step
    func goToStep(_ step: AudioSetupStep) {
        viewModel.goToStep(step)
    }

    // MARK: - Audio Status Checks

    /// Perform all audio setup checks
    func performAudioChecks() async {
        // Check BlackHole
        viewModel.checkBlackHole()

        // Wait a bit then check Multi-Output if BlackHole is OK
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        if viewModel.blackHoleStatus == .success {
            viewModel.checkMultiOutput()
        }

        // Wait then check system audio if Multi-Output is OK
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        if viewModel.multiOutputStatus == .success {
            viewModel.checkSystemAudio()
        }
    }

    /// Quick check if audio setup is valid (for app launch)
    func validateAudioSetup() -> AudioSetupValidationResult {
        let blackHoleStatus = BlackHoleDetector.detectBlackHole()
        let multiOutputStatus = MultiOutputDetector.detectMultiOutputDevice()
        let isDefaultConfigured = MultiOutputDetector.isDefaultOutputConfigured()

        // Check BlackHole
        guard case .installed = blackHoleStatus else {
            return .invalid(reason: .blackHoleNotInstalled)
        }

        // Check Multi-Output
        guard case .configured = multiOutputStatus else {
            return .invalid(reason: .multiOutputNotConfigured)
        }

        // Check default output
        guard isDefaultConfigured else {
            return .invalid(reason: .systemAudioNotConfigured)
        }

        return .valid
    }

    // MARK: - Private Methods

    private func handleWizardCompletion() {
        viewModel.completeSetup()
        onWizardComplete?()
    }

    // MARK: - Re-running Setup

    /// Force re-run of the audio setup wizard
    func rerunSetup() {
        viewModel.resetSetup()
        presentWizard()
        onSetupRequired?()
    }

    /// Check if setup needs to be re-run due to audio device changes
    func checkForDeviceChanges() {
        let validation = validateAudioSetup()

        if case .invalid = validation {
            // Audio setup is no longer valid
            onSetupRequired?()
        }
    }
}

// MARK: - Validation Result

/// Result of audio setup validation
enum AudioSetupValidationResult {
    case valid
    case invalid(reason: AudioSetupInvalidReason)

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
}

/// Reasons why audio setup might be invalid
enum AudioSetupInvalidReason {
    case blackHoleNotInstalled
    case multiOutputNotConfigured
    case systemAudioNotConfigured
    case verificationFailed

    var localizedDescription: String {
        switch self {
        case .blackHoleNotInstalled:
            return "BlackHole 2ch virtual audio device is not installed."
        case .multiOutputNotConfigured:
            return "Multi-Output Device is not properly configured."
        case .systemAudioNotConfigured:
            return "System audio output is not set to Multi-Output Device."
        case .verificationFailed:
            return "Audio capture verification failed."
        }
    }

    var recoveryStep: AudioSetupStep {
        switch self {
        case .blackHoleNotInstalled:
            return .blackHoleCheck
        case .multiOutputNotConfigured:
            return .multiOutputSetup
        case .systemAudioNotConfigured:
            return .systemAudioSelection
        case .verificationFailed:
            return .verification
        }
    }
}

// MARK: - Environment Key

private struct AudioSetupCoordinatorKey: EnvironmentKey {
    @MainActor static let defaultValue: AudioSetupCoordinator = AudioSetupCoordinator()
}

extension EnvironmentValues {
    var audioSetupCoordinator: AudioSetupCoordinator {
        get { self[AudioSetupCoordinatorKey.self] }
        set { self[AudioSetupCoordinatorKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Adds the audio setup wizard sheet to the view
    func audioSetupWizard(
        coordinator: AudioSetupCoordinator,
        onComplete: @escaping () -> Void = {}
    ) -> some View {
        let isPresentedBinding = Binding(
            get: { coordinator.isWizardPresented },
            set: { coordinator.isWizardPresented = $0 }
        )
        return self.sheet(isPresented: isPresentedBinding) {
            AudioSetupWizardView(
                isPresented: isPresentedBinding,
                onComplete: {
                    coordinator.completeAndDismiss()
                    onComplete()
                }
            )
            .environmentObject(coordinator.viewModel)
        }
    }
}
