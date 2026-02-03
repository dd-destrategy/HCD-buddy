//
//  AudioSetupViewModel.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - State Management
//

import Foundation
import SwiftUI
import Combine

/// Represents the current step in the audio setup wizard
enum AudioSetupStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case blackHoleCheck = 1
    case multiOutputSetup = 2
    case systemAudioSelection = 3
    case verification = 4
    case complete = 5

    var id: Int { rawValue }

    /// Human-readable title for the step
    var title: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .blackHoleCheck:
            return "BlackHole Check"
        case .multiOutputSetup:
            return "Multi-Output Setup"
        case .systemAudioSelection:
            return "System Audio"
        case .verification:
            return "Verification"
        case .complete:
            return "Complete"
        }
    }

    /// Accessibility description for VoiceOver
    var accessibilityDescription: String {
        switch self {
        case .welcome:
            return "Welcome to audio setup"
        case .blackHoleCheck:
            return "Checking for BlackHole virtual audio device"
        case .multiOutputSetup:
            return "Setting up Multi-Output device"
        case .systemAudioSelection:
            return "Selecting system audio output"
        case .verification:
            return "Verifying audio capture works"
        case .complete:
            return "Setup complete"
        }
    }

    /// Progress percentage for the current step
    var progressPercentage: Double {
        Double(rawValue) / Double(AudioSetupStep.allCases.count - 1)
    }
}

/// Represents the status of audio setup checks
enum AudioSetupStatus: Equatable {
    case pending
    case checking
    case success
    case failure(String)
    case skipped

    var isComplete: Bool {
        switch self {
        case .success, .skipped:
            return true
        default:
            return false
        }
    }
}

/// ViewModel managing the Audio Setup Wizard state
@MainActor
final class AudioSetupViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current step in the wizard
    @Published var currentStep: AudioSetupStep = .welcome

    /// Status of BlackHole detection
    @Published var blackHoleStatus: AudioSetupStatus = .pending

    /// Status of Multi-Output Device configuration
    @Published var multiOutputStatus: AudioSetupStatus = .pending

    /// Status of system audio selection
    @Published var systemAudioStatus: AudioSetupStatus = .pending

    /// Status of audio verification
    @Published var verificationStatus: AudioSetupStatus = .pending

    /// Error message to display
    @Published var errorMessage: String?

    /// Structured setup error for the current step (provides rich what/why/how info)
    @Published var currentSetupError: HCDError.AudioSetupError?

    /// Whether a check is currently in progress
    @Published var isChecking: Bool = false

    /// Audio levels during verification
    @Published var systemAudioLevel: Float = 0.0
    @Published var microphoneAudioLevel: Float = 0.0

    /// Whether verification test is playing
    @Published var isTestAudioPlaying: Bool = false

    /// Whether audio was detected during verification
    @Published var audioDetected: Bool = false

    // MARK: - UserDefaults Keys

    private enum UserDefaultsKeys {
        static let audioSetupCompleted = "hcd_audio_setup_completed"
        static let audioSetupCompletedDate = "hcd_audio_setup_completed_date"
        static let blackHoleDeviceID = "hcd_blackhole_device_id"
        static let multiOutputDeviceID = "hcd_multioutput_device_id"
        static let audioSetupSkipped = "hcd_audio_setup_skipped"
        static let audioSetupSkippedDate = "hcd_audio_setup_skipped_date"
    }

    // MARK: - Computed Properties

    /// Whether the user can proceed to the next step
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .blackHoleCheck:
            return blackHoleStatus.isComplete
        case .multiOutputSetup:
            return multiOutputStatus.isComplete
        case .systemAudioSelection:
            return systemAudioStatus.isComplete
        case .verification:
            return verificationStatus.isComplete
        case .complete:
            return true
        }
    }

    /// Whether the user can go back to the previous step
    var canGoBack: Bool {
        currentStep.rawValue > 0 && currentStep != .complete
    }

    /// Total number of steps
    var totalSteps: Int {
        AudioSetupStep.allCases.count
    }

    /// Current step number (1-indexed for display)
    var currentStepNumber: Int {
        currentStep.rawValue + 1
    }

    /// Whether audio setup has been previously completed
    var wasSetupPreviouslyCompleted: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.audioSetupCompleted)
    }

    /// Whether audio setup was skipped by the user
    var wasSetupSkipped: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.audioSetupSkipped)
    }

    /// Whether the app is running in limited mode (setup skipped, not completed)
    var isLimitedMode: Bool {
        wasSetupSkipped && !wasSetupPreviouslyCompleted
    }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var verificationTimer: Timer?

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Clear error message and structured error when step changes
        $currentStep
            .sink { [weak self] _ in
                self?.errorMessage = nil
                self?.currentSetupError = nil
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation

    /// Navigate to the next step
    func nextStep() {
        guard canProceed else { return }

        let nextRawValue = currentStep.rawValue + 1
        if let nextStep = AudioSetupStep(rawValue: nextRawValue) {
            currentStep = nextStep
            announceStepChange()
        }
    }

    /// Navigate to the previous step
    func previousStep() {
        guard canGoBack else { return }

        let previousRawValue = currentStep.rawValue - 1
        if let previousStep = AudioSetupStep(rawValue: previousRawValue) {
            currentStep = previousStep
            announceStepChange()
        }
    }

    /// Jump to a specific step
    func goToStep(_ step: AudioSetupStep) {
        currentStep = step
        announceStepChange()
    }

    /// Announce step change for VoiceOver
    private func announceStepChange() {
        let announcement = "Step \(currentStepNumber) of \(totalSteps): \(currentStep.accessibilityDescription)"
        #if os(macOS)
        NSAccessibility.post(
            element: NSApp.mainWindow as Any,
            notification: .announcementRequested,
            userInfo: [.announcement: announcement, .priority: NSAccessibilityPriorityLevel.high]
        )
        #endif
    }

    // MARK: - BlackHole Detection

    /// Check if BlackHole 2ch is installed
    func checkBlackHole() {
        isChecking = true
        blackHoleStatus = .checking
        currentSetupError = nil

        // Simulate async check with slight delay for UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let status = BlackHoleDetector.detectBlackHole()

            switch status {
            case .installed(let deviceID):
                self.blackHoleStatus = .success
                self.currentSetupError = nil
                UserDefaults.standard.set(deviceID, forKey: UserDefaultsKeys.blackHoleDeviceID)
            case .unknownVersion:
                let error = HCDError.AudioSetupError.blackHoleIncompatibleVersion
                self.currentSetupError = error
                self.blackHoleStatus = .failure(error.errorDescription ?? "Incompatible BlackHole version")
            case .notInstalled:
                let error = HCDError.AudioSetupError.blackHoleNotFound
                self.currentSetupError = error
                self.blackHoleStatus = .failure(error.errorDescription ?? "BlackHole not found")
            }

            self.isChecking = false
        }
    }

    // MARK: - Multi-Output Detection

    /// Check if Multi-Output Device is properly configured
    func checkMultiOutput() {
        isChecking = true
        multiOutputStatus = .checking
        currentSetupError = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let status = MultiOutputDetector.detectMultiOutputDevice()

            switch status {
            case .configured(let deviceID, _, _):
                self.multiOutputStatus = .success
                self.currentSetupError = nil
                UserDefaults.standard.set(deviceID, forKey: UserDefaultsKeys.multiOutputDeviceID)
            case .missingBlackHole:
                let error = HCDError.AudioSetupError.multiOutputMissingBlackHole
                self.currentSetupError = error
                self.multiOutputStatus = .failure(error.errorDescription ?? "Missing BlackHole in Multi-Output")
            case .missingSpeakers:
                let error = HCDError.AudioSetupError.multiOutputMissingSpeakers
                self.currentSetupError = error
                self.multiOutputStatus = .failure(error.errorDescription ?? "Missing speakers in Multi-Output")
            case .notConfigured:
                let error = HCDError.AudioSetupError.multiOutputNotConfigured
                self.currentSetupError = error
                self.multiOutputStatus = .failure(error.errorDescription ?? "Multi-Output not configured")
            case .notFound:
                let error = HCDError.AudioSetupError.multiOutputNotFound
                self.currentSetupError = error
                self.multiOutputStatus = .failure(error.errorDescription ?? "Multi-Output not found")
            }

            self.isChecking = false
        }
    }

    // MARK: - System Audio Selection

    /// Check if Multi-Output Device is set as default output
    func checkSystemAudio() {
        isChecking = true
        systemAudioStatus = .checking
        currentSetupError = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            if MultiOutputDetector.isDefaultOutputConfigured() {
                self.systemAudioStatus = .success
                self.currentSetupError = nil
            } else {
                let error = HCDError.AudioSetupError.systemAudioNotConfigured
                self.currentSetupError = error
                self.systemAudioStatus = .failure(error.errorDescription ?? "System audio not configured")
            }

            self.isChecking = false
        }
    }

    /// Mark system audio as manually configured
    func markSystemAudioConfigured() {
        systemAudioStatus = .success
    }

    // MARK: - Verification

    /// Start playing test audio for verification
    func startTestAudio() {
        isTestAudioPlaying = true
        audioDetected = false
        verificationStatus = .checking

        // Start monitoring audio levels
        startAudioLevelMonitoring()

        // Play system sound for testing
        playSystemTestSound()
    }

    /// Stop test audio playback
    func stopTestAudio() {
        isTestAudioPlaying = false
        stopAudioLevelMonitoring()
    }

    /// Mark verification as successful
    func confirmVerification() {
        verificationStatus = .success
        currentSetupError = nil
        stopTestAudio()
    }

    /// Mark verification as failed
    func failVerification(reason: String) {
        verificationStatus = .failure(reason)
        stopTestAudio()
    }

    /// Mark verification as failed with a structured error for rich display
    func failVerification(error: HCDError.AudioSetupError) {
        currentSetupError = error
        verificationStatus = .failure(error.errorDescription ?? "Verification failed")
        stopTestAudio()
    }

    private func playSystemTestSound() {
        #if os(macOS)
        // Play a system sound that can be captured
        NSSound.beep()

        // Schedule additional beeps for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSSound.beep()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSSound.beep()
        }
        #endif
    }

    private func startAudioLevelMonitoring() {
        // Simulate audio level monitoring
        verificationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                // Simulate varying audio levels during test
                if self.isTestAudioPlaying {
                    self.systemAudioLevel = Float.random(in: 0.3...0.8)
                    self.microphoneAudioLevel = Float.random(in: 0.0...0.2)

                    // Mark audio as detected if levels are above threshold
                    if self.systemAudioLevel > 0.4 {
                        self.audioDetected = true
                    }
                }
            }
        }
    }

    private func stopAudioLevelMonitoring() {
        verificationTimer?.invalidate()
        verificationTimer = nil
        systemAudioLevel = 0.0
        microphoneAudioLevel = 0.0
    }

    // MARK: - Completion

    /// Mark the audio setup as complete
    func completeSetup() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.audioSetupCompleted)
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.audioSetupCompletedDate)
    }

    /// Reset the audio setup status
    func resetSetup() {
        currentStep = .welcome
        blackHoleStatus = .pending
        multiOutputStatus = .pending
        systemAudioStatus = .pending
        verificationStatus = .pending
        errorMessage = nil
        currentSetupError = nil
        isChecking = false
        audioDetected = false

        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupCompleted)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupCompletedDate)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupSkipped)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupSkippedDate)
    }

    // MARK: - External Links

    /// Open BlackHole download page
    func openBlackHoleDownload() {
        if let url = URL(string: "https://existential.audio/blackhole/") {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }

    /// Open Audio MIDI Setup application
    func openAudioMIDISetup() {
        #if os(macOS)
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        NSWorkspace.shared.open(url)
        #endif
    }

    /// Open System Settings Sound preferences
    func openSystemSoundSettings() {
        #if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    /// Open troubleshooting documentation
    func openTroubleshootingGuide() {
        if let url = URL(string: "https://hcdinterviewcoach.app/docs/audio-troubleshooting") {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        }
    }

    // MARK: - Skip Options

    /// Skip the entire audio setup wizard
    /// The app will launch in limited/transcription-only mode
    func skipEntireSetup() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.audioSetupSkipped)
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.audioSetupSkippedDate)
    }

    /// Mark a step as already configured by an experienced user
    /// Skips the check and marks the step as successful
    func markBlackHoleAlreadyConfigured() {
        blackHoleStatus = .success
    }

    /// Mark Multi-Output as already configured by an experienced user
    func markMultiOutputAlreadyConfigured() {
        multiOutputStatus = .success
    }

    /// Clear the skip state so the user can re-enter the wizard
    func clearSkipState() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupSkipped)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupSkippedDate)
    }

    /// Skip BlackHole check (for users who know what they're doing)
    func skipBlackHoleCheck() {
        blackHoleStatus = .skipped
    }

    /// Skip Multi-Output setup (for advanced users)
    func skipMultiOutputSetup() {
        multiOutputStatus = .skipped
    }
}
