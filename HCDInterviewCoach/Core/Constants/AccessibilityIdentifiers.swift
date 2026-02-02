//
//  AccessibilityIdentifiers.swift
//  HCDInterviewCoach
//
//  Created by Agent E13
//  EPIC E13: Accessibility - Test Identifiers
//

import Foundation

/// Centralized accessibility identifiers for UI testing and automation
/// All interactive elements should have a consistent identifier
enum AccessibilityIdentifiers {

    // MARK: - Session Setup

    enum SessionSetup {
        static let container = "sessionSetupContainer"
        static let participantNameField = "participantNameField"
        static let projectNameField = "projectNameField"
        static let templatePicker = "templatePicker"
        static let modePicker = "sessionModePicker"
        static let startButton = "startSessionButton"
        static let cancelButton = "cancelSetupButton"
    }

    // MARK: - Main Session View

    enum Session {
        static let container = "activeSessionContainer"
        static let transcriptPanel = "transcriptPanel"
        static let topicPanel = "topicPanel"
        static let insightPanel = "insightPanel"
        static let controlsPanel = "sessionControlsPanel"
    }

    // MARK: - Session Controls

    enum Controls {
        static let startButton = "startRecordingButton"
        static let pauseButton = "pauseRecordingButton"
        static let resumeButton = "resumeRecordingButton"
        static let endButton = "endSessionButton"
        static let toggleCoachingButton = "toggleCoachingButton"
        static let connectionStatus = "connectionStatusIndicator"
    }

    // MARK: - Transcript

    enum Transcript {
        static let container = "transcriptContainer"
        static let list = "transcriptList"
        static let searchField = "transcriptSearchField"
        static let searchNextButton = "searchNextButton"
        static let searchPreviousButton = "searchPreviousButton"
        static let clearSearchButton = "clearSearchButton"

        static func utteranceRow(id: String) -> String {
            "utterance-\(id)"
        }

        static func speakerLabel(id: String) -> String {
            "speaker-\(id)"
        }

        static func timestamp(id: String) -> String {
            "timestamp-\(id)"
        }
    }

    // MARK: - Topics

    enum Topics {
        static let container = "topicsContainer"
        static let list = "topicsList"
        static let addButton = "addTopicButton"
        static let collapseButton = "collapseTopicsButton"

        static func topicRow(id: String) -> String {
            "topic-\(id)"
        }

        static func topicStatus(id: String) -> String {
            "topicStatus-\(id)"
        }

        static func editButton(id: String) -> String {
            "editTopic-\(id)"
        }

        static func deleteButton(id: String) -> String {
            "deleteTopic-\(id)"
        }
    }

    // MARK: - Insights

    enum Insights {
        static let container = "insightsContainer"
        static let list = "insightsList"
        static let flagButton = "flagInsightButton"
        static let collapseButton = "collapseInsightsButton"

        static func insightRow(id: String) -> String {
            "insight-\(id)"
        }

        static func editButton(id: String) -> String {
            "editInsight-\(id)"
        }

        static func deleteButton(id: String) -> String {
            "deleteInsight-\(id)"
        }

        static func navigateButton(id: String) -> String {
            "navigateToInsight-\(id)"
        }
    }

    // MARK: - Coaching

    enum Coaching {
        static let promptWindow = "coachingPromptWindow"
        static let promptMessage = "coachingPromptMessage"
        static let dismissButton = "dismissCoachingButton"
        static let countdownLabel = "coachingCountdown"
        static let muteIndicator = "coachingMuteIndicator"
    }

    // MARK: - Audio Setup Wizard

    enum AudioSetup {
        static let container = "audioSetupWizardContainer"
        static let welcomeStep = "welcomeStep"
        static let blackHoleStep = "blackHoleInstallStep"
        static let multiOutputStep = "multiOutputStep"
        static let verificationStep = "audioVerificationStep"
        static let successStep = "setupSuccessStep"

        static let nextButton = "wizardNextButton"
        static let backButton = "wizardBackButton"
        static let skipButton = "wizardSkipButton"
        static let progressIndicator = "wizardProgressIndicator"

        static let systemLevelMeter = "systemAudioLevelMeter"
        static let microphoneLevelMeter = "microphoneLevelMeter"
        static let verificationButton = "verifyAudioButton"
    }

    // MARK: - Post-Session Summary

    enum Summary {
        static let container = "postSessionSummaryContainer"
        static let durationLabel = "sessionDuration"
        static let participantLabel = "participantName"
        static let topicSummary = "topicCoverageSummary"
        static let insightCount = "insightCount"
        static let aiReflection = "aiReflection"

        static let exportButton = "exportSessionButton"
        static let viewTranscriptButton = "viewTranscriptButton"
        static let newSessionButton = "startNewSessionButton"
        static let closeButton = "closeSummaryButton"
    }

    // MARK: - Export

    enum Export {
        static let dialog = "exportDialog"
        static let formatPicker = "exportFormatPicker"
        static let saveButton = "saveExportButton"
        static let cancelButton = "cancelExportButton"
        static let includeCoachingToggle = "includeCoachingLogToggle"
        static let includeTopicsToggle = "includeTopicsToggle"
        static let progressIndicator = "exportProgressIndicator"
    }

    // MARK: - Settings

    enum Settings {
        static let window = "settingsWindow"
        static let generalTab = "generalSettingsTab"
        static let audioTab = "audioSettingsTab"
        static let coachingTab = "coachingSettingsTab"
        static let privacyTab = "privacySettingsTab"

        // General
        static let defaultModepicker = "defaultSessionMode"
        static let defaultTemplatePicker = "defaultTemplate"
        static let checkUpdatesToggle = "checkForUpdatesToggle"

        // Audio
        static let inputDevicePicker = "audioInputDevice"
        static let rerunWizardButton = "rerunAudioWizard"
        static let testAudioButton = "testAudioButton"

        // Coaching
        static let coachingEnabledToggle = "coachingEnabledToggle"
        static let autoDismissSlider = "autoDismissTimeSlider"
        static let promptPositionPicker = "promptPositionPicker"
        static let resetDefaultsButton = "resetCoachingDefaults"
        static let previewPromptButton = "previewCoachingPrompt"

        // Privacy/API
        static let apiKeyField = "apiKeyField"
        static let updateKeyButton = "updateApiKeyButton"
        static let removeKeyButton = "removeApiKeyButton"
        static let testKeyButton = "testApiKeyButton"
    }

    // MARK: - Consent Templates

    enum Consent {
        static let container = "consentTemplateContainer"
        static let templatePicker = "consentTemplatePicker"
        static let textView = "consentTextView"
        static let copyButton = "copyConsentButton"
    }

    // MARK: - Session History

    enum History {
        static let container = "sessionHistoryContainer"
        static let list = "sessionHistoryList"
        static let searchField = "historySearchField"
        static let filterPicker = "historyFilterPicker"

        static func sessionRow(id: String) -> String {
            "historySession-\(id)"
        }

        static func viewButton(id: String) -> String {
            "viewSession-\(id)"
        }

        static func exportButton(id: String) -> String {
            "exportSession-\(id)"
        }

        static func deleteButton(id: String) -> String {
            "deleteSession-\(id)"
        }
    }

    // MARK: - Alerts and Modals

    enum Alerts {
        static let confirmEndSession = "confirmEndSessionAlert"
        static let confirmDeleteInsight = "confirmDeleteInsightAlert"
        static let confirmDeleteTopic = "confirmDeleteTopicAlert"
        static let confirmDeleteSession = "confirmDeleteSessionAlert"
        static let errorAlert = "errorAlert"
        static let successAlert = "successAlert"

        static let confirmButton = "alertConfirmButton"
        static let cancelButton = "alertCancelButton"
    }

    // MARK: - Common Elements

    enum Common {
        static let closeButton = "closeButton"
        static let saveButton = "saveButton"
        static let cancelButton = "cancelButton"
        static let deleteButton = "deleteButton"
        static let editButton = "editButton"
        static let backButton = "backButton"
        static let nextButton = "nextButton"
    }
}
