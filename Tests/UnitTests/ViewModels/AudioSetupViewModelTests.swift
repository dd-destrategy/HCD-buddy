//
//  AudioSetupViewModelTests.swift
//  HCDInterviewCoach Tests
//
//  EPIC E14: Testing & Quality
//  Unit tests for AudioSetupViewModel - Audio Setup Wizard State Management
//

import XCTest
import Combine
@testable import HCDInterviewCoach

@MainActor
final class AudioSetupViewModelTests: XCTestCase {

    var viewModel: AudioSetupViewModel!
    var cancellables: Set<AnyCancellable>!

    // MARK: - UserDefaults Keys (matching the ViewModel)

    private enum UserDefaultsKeys {
        static let audioSetupCompleted = "hcd_audio_setup_completed"
        static let audioSetupCompletedDate = "hcd_audio_setup_completed_date"
        static let blackHoleDeviceID = "hcd_blackhole_device_id"
        static let multiOutputDeviceID = "hcd_multioutput_device_id"
    }

    override func setUp() {
        super.setUp()
        viewModel = AudioSetupViewModel()
        cancellables = Set<AnyCancellable>()

        // Clear UserDefaults before each test
        clearUserDefaults()
    }

    override func tearDown() {
        viewModel = nil
        cancellables = nil
        clearUserDefaults()
        super.tearDown()
    }

    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupCompleted)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.audioSetupCompletedDate)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.blackHoleDeviceID)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.multiOutputDeviceID)
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Given: Fresh view model

        // Then: Should have default initial values
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertEqual(viewModel.blackHoleStatus, .pending)
        XCTAssertEqual(viewModel.multiOutputStatus, .pending)
        XCTAssertEqual(viewModel.systemAudioStatus, .pending)
        XCTAssertEqual(viewModel.verificationStatus, .pending)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isChecking)
        XCTAssertEqual(viewModel.systemAudioLevel, 0.0)
        XCTAssertEqual(viewModel.microphoneAudioLevel, 0.0)
        XCTAssertFalse(viewModel.isTestAudioPlaying)
        XCTAssertFalse(viewModel.audioDetected)
    }

    func testInitialState_canProceedFromWelcome() {
        // Given: View model at welcome step

        // Then: Should be able to proceed
        XCTAssertTrue(viewModel.canProceed)
    }

    func testInitialState_cannotGoBackFromWelcome() {
        // Given: View model at welcome step

        // Then: Should not be able to go back
        XCTAssertFalse(viewModel.canGoBack)
    }

    // MARK: - Navigation Tests

    func testNextStep_fromWelcome() {
        // Given: At welcome step
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // When: Go to next step
        viewModel.nextStep()

        // Then: Should be at blackHoleCheck
        XCTAssertEqual(viewModel.currentStep, .blackHoleCheck)
    }

    func testNextStep_requiresCompletionForBlackHoleStep() {
        // Given: At blackHoleCheck step with pending status
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .pending

        // When: Try to go to next step
        viewModel.nextStep()

        // Then: Should still be at blackHoleCheck (cannot proceed)
        XCTAssertEqual(viewModel.currentStep, .blackHoleCheck)
        XCTAssertFalse(viewModel.canProceed)
    }

    func testNextStep_allowsWhenBlackHoleSuccess() {
        // Given: At blackHoleCheck step with success status
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .success

        // When: Go to next step
        viewModel.nextStep()

        // Then: Should be at multiOutputSetup
        XCTAssertEqual(viewModel.currentStep, .multiOutputSetup)
    }

    func testNextStep_allowsWhenSkipped() {
        // Given: At blackHoleCheck step with skipped status
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .skipped

        // When: Go to next step
        viewModel.nextStep()

        // Then: Should be at multiOutputSetup
        XCTAssertEqual(viewModel.currentStep, .multiOutputSetup)
    }

    func testPreviousStep_fromBlackHoleCheck() {
        // Given: At blackHoleCheck step
        viewModel.currentStep = .blackHoleCheck

        // When: Go to previous step
        viewModel.previousStep()

        // Then: Should be at welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func testPreviousStep_cannotGoBackFromWelcome() {
        // Given: At welcome step
        viewModel.currentStep = .welcome

        // When: Try to go to previous step
        viewModel.previousStep()

        // Then: Should still be at welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func testPreviousStep_cannotGoBackFromComplete() {
        // Given: At complete step
        viewModel.currentStep = .complete

        // When: Try to go to previous step
        viewModel.previousStep()

        // Then: Should still be at complete (canGoBack is false for complete)
        XCTAssertEqual(viewModel.currentStep, .complete)
    }

    // MARK: - canProceed Tests

    func testCanProceed_welcomeAlwaysTrue() {
        viewModel.currentStep = .welcome
        XCTAssertTrue(viewModel.canProceed)
    }

    func testCanProceed_blackHoleCheckPendingFalse() {
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .pending
        XCTAssertFalse(viewModel.canProceed)
    }

    func testCanProceed_blackHoleCheckCheckingFalse() {
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .checking
        XCTAssertFalse(viewModel.canProceed)
    }

    func testCanProceed_blackHoleCheckSuccessTrue() {
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .success
        XCTAssertTrue(viewModel.canProceed)
    }

    func testCanProceed_blackHoleCheckSkippedTrue() {
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .skipped
        XCTAssertTrue(viewModel.canProceed)
    }

    func testCanProceed_blackHoleCheckFailureFalse() {
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .failure("Test error")
        XCTAssertFalse(viewModel.canProceed)
    }

    func testCanProceed_multiOutputSetupRequiresSuccess() {
        viewModel.currentStep = .multiOutputSetup
        viewModel.multiOutputStatus = .pending
        XCTAssertFalse(viewModel.canProceed)

        viewModel.multiOutputStatus = .success
        XCTAssertTrue(viewModel.canProceed)
    }

    func testCanProceed_systemAudioRequiresSuccess() {
        viewModel.currentStep = .systemAudioSelection
        viewModel.systemAudioStatus = .pending
        XCTAssertFalse(viewModel.canProceed)

        viewModel.systemAudioStatus = .success
        XCTAssertTrue(viewModel.canProceed)
    }

    func testCanProceed_verificationRequiresSuccess() {
        viewModel.currentStep = .verification
        viewModel.verificationStatus = .pending
        XCTAssertFalse(viewModel.canProceed)

        viewModel.verificationStatus = .success
        XCTAssertTrue(viewModel.canProceed)
    }

    func testCanProceed_completeAlwaysTrue() {
        viewModel.currentStep = .complete
        XCTAssertTrue(viewModel.canProceed)
    }

    // MARK: - canGoBack Tests

    func testCanGoBack_welcomeFalse() {
        viewModel.currentStep = .welcome
        XCTAssertFalse(viewModel.canGoBack)
    }

    func testCanGoBack_blackHoleCheckTrue() {
        viewModel.currentStep = .blackHoleCheck
        XCTAssertTrue(viewModel.canGoBack)
    }

    func testCanGoBack_multiOutputSetupTrue() {
        viewModel.currentStep = .multiOutputSetup
        XCTAssertTrue(viewModel.canGoBack)
    }

    func testCanGoBack_systemAudioSelectionTrue() {
        viewModel.currentStep = .systemAudioSelection
        XCTAssertTrue(viewModel.canGoBack)
    }

    func testCanGoBack_verificationTrue() {
        viewModel.currentStep = .verification
        XCTAssertTrue(viewModel.canGoBack)
    }

    func testCanGoBack_completeFalse() {
        viewModel.currentStep = .complete
        XCTAssertFalse(viewModel.canGoBack)
    }

    // MARK: - Step Number and Progress Tests

    func testCurrentStepNumber() {
        viewModel.currentStep = .welcome
        XCTAssertEqual(viewModel.currentStepNumber, 1)

        viewModel.currentStep = .blackHoleCheck
        XCTAssertEqual(viewModel.currentStepNumber, 2)

        viewModel.currentStep = .multiOutputSetup
        XCTAssertEqual(viewModel.currentStepNumber, 3)

        viewModel.currentStep = .systemAudioSelection
        XCTAssertEqual(viewModel.currentStepNumber, 4)

        viewModel.currentStep = .verification
        XCTAssertEqual(viewModel.currentStepNumber, 5)

        viewModel.currentStep = .complete
        XCTAssertEqual(viewModel.currentStepNumber, 6)
    }

    func testTotalSteps() {
        XCTAssertEqual(viewModel.totalSteps, 6)
    }

    func testProgressPercentage() {
        // Progress is calculated as rawValue / (allCases.count - 1)
        XCTAssertEqual(AudioSetupStep.welcome.progressPercentage, 0.0)
        XCTAssertEqual(AudioSetupStep.blackHoleCheck.progressPercentage, 0.2)
        XCTAssertEqual(AudioSetupStep.multiOutputSetup.progressPercentage, 0.4)
        XCTAssertEqual(AudioSetupStep.systemAudioSelection.progressPercentage, 0.6)
        XCTAssertEqual(AudioSetupStep.verification.progressPercentage, 0.8)
        XCTAssertEqual(AudioSetupStep.complete.progressPercentage, 1.0)
    }

    // MARK: - GoToStep Tests

    func testGoToStep_directNavigation() {
        // Given: At welcome step
        XCTAssertEqual(viewModel.currentStep, .welcome)

        // When: Go directly to verification step
        viewModel.goToStep(.verification)

        // Then: Should be at verification step
        XCTAssertEqual(viewModel.currentStep, .verification)
    }

    func testGoToStep_backwardsNavigation() {
        // Given: At verification step
        viewModel.currentStep = .verification

        // When: Go directly to blackHoleCheck step
        viewModel.goToStep(.blackHoleCheck)

        // Then: Should be at blackHoleCheck step
        XCTAssertEqual(viewModel.currentStep, .blackHoleCheck)
    }

    // MARK: - BlackHole Detection Tests

    func testBlackHoleDetection_setsChecking() async {
        // Given: At blackHoleCheck step
        viewModel.currentStep = .blackHoleCheck

        // When: Start checking
        viewModel.checkBlackHole()

        // Then: Should be checking
        XCTAssertTrue(viewModel.isChecking)
        XCTAssertEqual(viewModel.blackHoleStatus, .checking)
    }

    func testBlackHoleDetection_completesCheck() async throws {
        // Given: At blackHoleCheck step
        viewModel.currentStep = .blackHoleCheck

        // When: Check BlackHole
        viewModel.checkBlackHole()

        // Wait for async check to complete (simulated delay is 0.5s)
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7s

        // Then: Should no longer be checking
        XCTAssertFalse(viewModel.isChecking)
        // Status will depend on actual BlackHole installation
    }

    // MARK: - Multi-Output Detection Tests

    func testMultiOutputDetection_setsChecking() async {
        // Given: At multiOutputSetup step
        viewModel.currentStep = .multiOutputSetup

        // When: Start checking
        viewModel.checkMultiOutput()

        // Then: Should be checking
        XCTAssertTrue(viewModel.isChecking)
        XCTAssertEqual(viewModel.multiOutputStatus, .checking)
    }

    func testMultiOutputDetection_completesCheck() async throws {
        // Given: At multiOutputSetup step
        viewModel.currentStep = .multiOutputSetup

        // When: Check Multi-Output
        viewModel.checkMultiOutput()

        // Wait for async check to complete
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7s

        // Then: Should no longer be checking
        XCTAssertFalse(viewModel.isChecking)
    }

    // MARK: - System Audio Tests

    func testSystemAudioCheck_setsChecking() async {
        // Given: At systemAudioSelection step
        viewModel.currentStep = .systemAudioSelection

        // When: Start checking
        viewModel.checkSystemAudio()

        // Then: Should be checking
        XCTAssertTrue(viewModel.isChecking)
        XCTAssertEqual(viewModel.systemAudioStatus, .checking)
    }

    func testMarkSystemAudioConfigured_setsSuccess() {
        // Given: At systemAudioSelection step with pending status
        viewModel.currentStep = .systemAudioSelection
        viewModel.systemAudioStatus = .pending

        // When: Mark as configured
        viewModel.markSystemAudioConfigured()

        // Then: Status should be success
        XCTAssertEqual(viewModel.systemAudioStatus, .success)
    }

    // MARK: - Verification Tests

    func testVerificationSuccess_setsStatus() {
        // Given: At verification step
        viewModel.currentStep = .verification

        // When: Confirm verification
        viewModel.confirmVerification()

        // Then: Status should be success
        XCTAssertEqual(viewModel.verificationStatus, .success)
        XCTAssertFalse(viewModel.isTestAudioPlaying)
    }

    func testVerificationFailure_setsStatusWithReason() {
        // Given: At verification step
        viewModel.currentStep = .verification

        // When: Fail verification with reason
        viewModel.failVerification(reason: "No audio detected")

        // Then: Status should be failure with reason
        if case .failure(let reason) = viewModel.verificationStatus {
            XCTAssertEqual(reason, "No audio detected")
        } else {
            XCTFail("Expected failure status")
        }
        XCTAssertFalse(viewModel.isTestAudioPlaying)
    }

    func testStartTestAudio_setsPlayingState() {
        // Given: At verification step
        viewModel.currentStep = .verification

        // When: Start test audio
        viewModel.startTestAudio()

        // Then: Should be playing
        XCTAssertTrue(viewModel.isTestAudioPlaying)
        XCTAssertFalse(viewModel.audioDetected)
        XCTAssertEqual(viewModel.verificationStatus, .checking)
    }

    func testStopTestAudio_clearsPlayingState() {
        // Given: Test audio is playing
        viewModel.isTestAudioPlaying = true
        viewModel.systemAudioLevel = 0.5
        viewModel.microphoneAudioLevel = 0.3

        // When: Stop test audio
        viewModel.stopTestAudio()

        // Then: Should not be playing and levels should reset
        XCTAssertFalse(viewModel.isTestAudioPlaying)
        XCTAssertEqual(viewModel.systemAudioLevel, 0.0)
        XCTAssertEqual(viewModel.microphoneAudioLevel, 0.0)
    }

    // MARK: - Setup Completion Tests

    func testSetupCompletion_savesToUserDefaults() {
        // Given: Setup not completed
        XCTAssertFalse(viewModel.wasSetupPreviouslyCompleted)

        // When: Complete setup
        viewModel.completeSetup()

        // Then: Should be saved to UserDefaults
        XCTAssertTrue(UserDefaults.standard.bool(forKey: UserDefaultsKeys.audioSetupCompleted))
        XCTAssertNotNil(UserDefaults.standard.object(forKey: UserDefaultsKeys.audioSetupCompletedDate))
    }

    func testWasSetupPreviouslyCompleted_readsFromUserDefaults() {
        // Given: Setup was completed
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.audioSetupCompleted)

        // When: Create new view model
        let newViewModel = AudioSetupViewModel()

        // Then: Should reflect completed status
        XCTAssertTrue(newViewModel.wasSetupPreviouslyCompleted)
    }

    // MARK: - Reset Setup Tests

    func testResetSetup_clearsAllState() {
        // Given: View model with various states set
        viewModel.currentStep = .verification
        viewModel.blackHoleStatus = .success
        viewModel.multiOutputStatus = .success
        viewModel.systemAudioStatus = .success
        viewModel.verificationStatus = .success
        viewModel.errorMessage = "Test error"
        viewModel.isChecking = true
        viewModel.audioDetected = true
        viewModel.completeSetup()

        // When: Reset setup
        viewModel.resetSetup()

        // Then: All state should be reset
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertEqual(viewModel.blackHoleStatus, .pending)
        XCTAssertEqual(viewModel.multiOutputStatus, .pending)
        XCTAssertEqual(viewModel.systemAudioStatus, .pending)
        XCTAssertEqual(viewModel.verificationStatus, .pending)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isChecking)
        XCTAssertFalse(viewModel.audioDetected)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultsKeys.audioSetupCompleted))
    }

    func testResetSetup_clearsUserDefaults() {
        // Given: Setup was completed
        viewModel.completeSetup()
        UserDefaults.standard.set(42, forKey: UserDefaultsKeys.blackHoleDeviceID)

        // When: Reset setup
        viewModel.resetSetup()

        // Then: UserDefaults should be cleared
        XCTAssertFalse(UserDefaults.standard.bool(forKey: UserDefaultsKeys.audioSetupCompleted))
        XCTAssertNil(UserDefaults.standard.object(forKey: UserDefaultsKeys.audioSetupCompletedDate))
    }

    // MARK: - Skip Options Tests

    func testSkipBlackHoleCheck_setsSkippedStatus() {
        // Given: At blackHoleCheck step
        viewModel.currentStep = .blackHoleCheck
        viewModel.blackHoleStatus = .pending

        // When: Skip check
        viewModel.skipBlackHoleCheck()

        // Then: Status should be skipped
        XCTAssertEqual(viewModel.blackHoleStatus, .skipped)
        XCTAssertTrue(viewModel.canProceed)
    }

    func testSkipMultiOutputSetup_setsSkippedStatus() {
        // Given: At multiOutputSetup step
        viewModel.currentStep = .multiOutputSetup
        viewModel.multiOutputStatus = .pending

        // When: Skip setup
        viewModel.skipMultiOutputSetup()

        // Then: Status should be skipped
        XCTAssertEqual(viewModel.multiOutputStatus, .skipped)
        XCTAssertTrue(viewModel.canProceed)
    }

    // MARK: - Error Message Tests

    func testErrorMessage_clearsOnStepChange() async throws {
        // Given: Error message is set
        viewModel.errorMessage = "Test error message"

        // When: Change step
        viewModel.nextStep()

        // Wait for Combine to propagate
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Error message should be cleared
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - AudioSetupStep Tests

    func testAudioSetupStep_titles() {
        XCTAssertEqual(AudioSetupStep.welcome.title, "Welcome")
        XCTAssertEqual(AudioSetupStep.blackHoleCheck.title, "BlackHole Check")
        XCTAssertEqual(AudioSetupStep.multiOutputSetup.title, "Multi-Output Setup")
        XCTAssertEqual(AudioSetupStep.systemAudioSelection.title, "System Audio")
        XCTAssertEqual(AudioSetupStep.verification.title, "Verification")
        XCTAssertEqual(AudioSetupStep.complete.title, "Complete")
    }

    func testAudioSetupStep_accessibilityDescriptions() {
        XCTAssertEqual(AudioSetupStep.welcome.accessibilityDescription, "Welcome to audio setup")
        XCTAssertEqual(AudioSetupStep.blackHoleCheck.accessibilityDescription, "Checking for BlackHole virtual audio device")
        XCTAssertEqual(AudioSetupStep.multiOutputSetup.accessibilityDescription, "Setting up Multi-Output device")
        XCTAssertEqual(AudioSetupStep.systemAudioSelection.accessibilityDescription, "Selecting system audio output")
        XCTAssertEqual(AudioSetupStep.verification.accessibilityDescription, "Verifying audio capture works")
        XCTAssertEqual(AudioSetupStep.complete.accessibilityDescription, "Setup complete")
    }

    func testAudioSetupStep_identifiable() {
        // Each step should have a unique ID based on its raw value
        let allSteps = AudioSetupStep.allCases
        let ids = allSteps.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    // MARK: - AudioSetupStatus Tests

    func testAudioSetupStatus_isComplete() {
        XCTAssertFalse(AudioSetupStatus.pending.isComplete)
        XCTAssertFalse(AudioSetupStatus.checking.isComplete)
        XCTAssertTrue(AudioSetupStatus.success.isComplete)
        XCTAssertFalse(AudioSetupStatus.failure("error").isComplete)
        XCTAssertTrue(AudioSetupStatus.skipped.isComplete)
    }

    func testAudioSetupStatus_equatable() {
        XCTAssertEqual(AudioSetupStatus.pending, AudioSetupStatus.pending)
        XCTAssertEqual(AudioSetupStatus.checking, AudioSetupStatus.checking)
        XCTAssertEqual(AudioSetupStatus.success, AudioSetupStatus.success)
        XCTAssertEqual(AudioSetupStatus.failure("error"), AudioSetupStatus.failure("error"))
        XCTAssertEqual(AudioSetupStatus.skipped, AudioSetupStatus.skipped)
        XCTAssertNotEqual(AudioSetupStatus.failure("error1"), AudioSetupStatus.failure("error2"))
    }

    // MARK: - Full Wizard Flow Test

    func testFullWizardFlow() {
        // Step 1: Welcome
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertTrue(viewModel.canProceed)
        viewModel.nextStep()

        // Step 2: BlackHole Check
        XCTAssertEqual(viewModel.currentStep, .blackHoleCheck)
        XCTAssertFalse(viewModel.canProceed)
        viewModel.blackHoleStatus = .success
        XCTAssertTrue(viewModel.canProceed)
        viewModel.nextStep()

        // Step 3: Multi-Output Setup
        XCTAssertEqual(viewModel.currentStep, .multiOutputSetup)
        XCTAssertFalse(viewModel.canProceed)
        viewModel.multiOutputStatus = .success
        XCTAssertTrue(viewModel.canProceed)
        viewModel.nextStep()

        // Step 4: System Audio Selection
        XCTAssertEqual(viewModel.currentStep, .systemAudioSelection)
        XCTAssertFalse(viewModel.canProceed)
        viewModel.markSystemAudioConfigured()
        XCTAssertTrue(viewModel.canProceed)
        viewModel.nextStep()

        // Step 5: Verification
        XCTAssertEqual(viewModel.currentStep, .verification)
        XCTAssertFalse(viewModel.canProceed)
        viewModel.confirmVerification()
        XCTAssertTrue(viewModel.canProceed)
        viewModel.nextStep()

        // Step 6: Complete
        XCTAssertEqual(viewModel.currentStep, .complete)
        XCTAssertTrue(viewModel.canProceed)
        XCTAssertFalse(viewModel.canGoBack)
    }
}
