//
//  ConsentFlowView.swift
//  HCDInterviewCoach
//
//  FEATURE H: Accessible Consent System
//  Multi-step wizard for obtaining informed consent from interview participants.
//  Supports multiple languages, text-to-speech, and full accessibility.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import AVFoundation
#endif

// MARK: - Consent Flow Step

/// The steps in the consent wizard flow
private enum ConsentFlowStep: Int, CaseIterable {
    case languageSelection = 0
    case introduction = 1
    case permissionsReview = 2
    case digitalSignature = 3

    var title: String {
        switch self {
        case .languageSelection: return "Choose Language"
        case .introduction: return "Welcome"
        case .permissionsReview: return "Your Permissions"
        case .digitalSignature: return "Confirm"
        }
    }

    var stepNumber: Int { rawValue + 1 }
    static var totalSteps: Int { allCases.count }
}

// MARK: - Consent Flow View

/// A multi-step wizard view for obtaining informed consent before an interview session.
///
/// The flow guides the participant through language selection, an introduction,
/// individual permission review, and a digital signature confirmation step.
/// All text is written at a 5th-grade reading level for maximum accessibility.
struct ConsentFlowView: View {

    // MARK: - Properties

    @ObservedObject var consentTracker: ConsentTracker
    var sessionId: UUID
    var onComplete: ((ConsentStatus) -> Void)
    var onDismiss: (() -> Void)

    // MARK: - State

    @State private var currentStep: ConsentFlowStep = .languageSelection
    @State private var selectedLanguage: ConsentLanguage = .english
    @State private var template: ConsentTemplate = ConsentTemplate.defaultEnglish()
    @State private var participantName: String = ""
    @State private var isSpeaking: Bool = false

    #if os(macOS)
    @State private var speechSynthesizer: NSSpeechSynthesizer?
    #else
    @State private var speechSynthesizer: AVSpeechSynthesizer?
    #endif

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            headerView
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

            Divider()

            // Step content
            ScrollView {
                stepContent
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.lg)
            }

            Divider()

            // Navigation buttons
            navigationBar
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.lg)
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
        .glassSheet()
        .onDisappear {
            stopSpeaking()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: Spacing.sm) {
            Text(currentStep.title)
                .font(Typography.heading1)
                .foregroundColor(.hcdTextPrimary)
                .accessibilityAddTraits(.isHeader)

            progressIndicator
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(ConsentFlowStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue
                          ? Color.accentColor
                          : Color.hcdTextSecondary.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("Step \(step.stepNumber) of \(ConsentFlowStep.totalSteps): \(step.title)")
                    .accessibilityValue(step.rawValue <= currentStep.rawValue ? "completed" : "not started")

                if step != ConsentFlowStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue
                              ? Color.accentColor
                              : Color.hcdTextSecondary.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Step Content Router

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .languageSelection:
            languageSelectionView
        case .introduction:
            introductionView
        case .permissionsReview:
            permissionsReviewView
        case .digitalSignature:
            digitalSignatureView
        }
    }

    // MARK: - Step 1: Language Selection

    private var languageSelectionView: some View {
        VStack(spacing: Spacing.xl) {
            Text("What language do you prefer?")
                .font(Typography.heading2)
                .foregroundColor(.hcdTextPrimary)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                ForEach(ConsentLanguage.allCases, id: \.rawValue) { language in
                    languageCard(for: language)
                }
            }
            .padding(.top, Spacing.md)
        }
    }

    private func languageCard(for language: ConsentLanguage) -> some View {
        let isSelected = selectedLanguage == language

        return Button(action: {
            selectedLanguage = language
            updateTemplateForLanguage(language)
        }) {
            VStack(spacing: Spacing.sm) {
                Text(language.icon)
                    .font(.system(size: 36))
                    .accessibilityHidden(true)

                Text(language.nativeName)
                    .font(Typography.heading3)
                    .foregroundColor(.hcdTextPrimary)

                Text(language.displayName)
                    .font(Typography.caption)
                    .foregroundColor(.hcdTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.md)
            .glassCard(isSelected: isSelected, accentColor: .accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(language.displayName), \(language.nativeName)")
        .accessibilityHint(isSelected ? "Currently selected" : "Double-click to select this language")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Step 2: Introduction

    private var introductionView: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text(template.introductionText)
                .font(Typography.heading3)
                .foregroundColor(.hcdTextPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(template.introductionText)

            readAloudButton(text: template.introductionText)

            Spacer(minLength: Spacing.lg)

            infoCard(
                icon: "info.circle.fill",
                text: "You will review each permission on the next screen. You can say yes or no to each one."
            )
        }
    }

    // MARK: - Step 3: Permissions Review

    private var permissionsReviewView: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Review each item below")
                    .font(Typography.heading2)
                    .foregroundColor(.hcdTextPrimary)

                Spacer()

                acceptAllButton
            }

            ForEach(template.permissions.indices, id: \.self) { index in
                permissionCard(at: index)
            }

            Text("\(template.acceptedCount) of \(template.permissionCount) accepted")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .accessibilityLabel("\(template.acceptedCount) of \(template.permissionCount) permissions accepted")
        }
    }

    private var acceptAllButton: some View {
        Button(action: acceptAllPermissions) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                Text("Accept All")
                    .font(Typography.bodyMedium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassButton(isActive: false, style: .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Accept all permissions")
        .accessibilityHint("Marks all permissions as accepted")
    }

    private func permissionCard(at index: Int) -> some View {
        let permission = template.permissions[index]
        let isAccepted = permission.isAccepted

        return HStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: permission.icon)
                .font(.system(size: 28))
                .foregroundColor(isAccepted ? .hcdSuccess : .hcdTextSecondary)
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)

            // Text content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(permission.title)
                        .font(Typography.heading3)
                        .foregroundColor(.hcdTextPrimary)

                    if permission.isRequired {
                        requiredBadge
                    }
                }

                Text(permission.description)
                    .font(Typography.body)
                    .foregroundColor(.hcdTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { template.permissions[index].isAccepted },
                set: { newValue in
                    template.permissions[index].isAccepted = newValue
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .accessibilityLabel("\(permission.title)")
            .accessibilityHint(permission.isRequired
                ? "Required. \(permission.description)"
                : "Optional. \(permission.description)")
            .accessibilityValue(isAccepted ? "Accepted" : "Not accepted")
        }
        .padding(Spacing.lg)
        .glassCard(isSelected: isAccepted, accentColor: .hcdSuccess)
    }

    private var requiredBadge: some View {
        Text("Required")
            .font(Typography.small)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.hcdWarning)
            )
            .accessibilityLabel("Required permission")
    }

    // MARK: - Step 4: Digital Signature

    private var digitalSignatureView: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            // Summary of accepted permissions
            permissionsSummary

            Divider()

            // Signature area
            signatureArea

            // Template info
            templateInfoRow
        }
    }

    private var permissionsSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Permissions Summary")
                .font(Typography.heading2)
                .foregroundColor(.hcdTextPrimary)
                .accessibilityAddTraits(.isHeader)

            ForEach(template.permissions) { permission in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: permission.isAccepted ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(permission.isAccepted ? .hcdSuccess : .hcdTextSecondary)
                        .font(.system(size: 16))
                        .accessibilityHidden(true)

                    Text(permission.title)
                        .font(Typography.body)
                        .foregroundColor(.hcdTextPrimary)

                    if permission.isRequired {
                        Text("(required)")
                            .font(Typography.caption)
                            .foregroundColor(.hcdWarning)
                    }

                    Spacer()

                    Text(permission.isAccepted ? "Yes" : "No")
                        .font(Typography.bodyMedium)
                        .foregroundColor(permission.isAccepted ? .hcdSuccess : .hcdTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(permission.title): \(permission.isAccepted ? "Accepted" : "Not accepted")\(permission.isRequired ? ", required" : "")")
            }
        }
    }

    private var signatureArea: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Signature")
                .font(Typography.heading2)
                .foregroundColor(.hcdTextPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Type your name below to confirm your choices.")
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)

            TextField("Type your full name", text: $participantName)
                .textFieldStyle(.roundedBorder)
                .font(Typography.heading3)
                .padding(.vertical, Spacing.xs)
                .accessibilityLabel("Participant name")
                .accessibilityHint("Type your full name to confirm consent")

            HStack(spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Date")
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)
                    Text(formattedDate)
                        .font(Typography.bodyMedium)
                        .foregroundColor(.hcdTextPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Date: \(formattedDate)")

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Template Version")
                        .font(Typography.caption)
                        .foregroundColor(.hcdTextSecondary)
                    Text(template.version)
                        .font(Typography.bodyMedium)
                        .foregroundColor(.hcdTextPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Template version \(template.version)")
            }
        }
    }

    private var templateInfoRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Divider()

            Text(template.closingText)
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Back / Dismiss
            if currentStep == .languageSelection {
                Button(action: {
                    stopSpeaking()
                    onDismiss()
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Cancel")
                            .font(Typography.bodyMedium)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .glassButton(style: .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel consent flow")
                .accessibilityHint("Closes the consent wizard without saving")
            } else {
                Button(action: goBack) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(Typography.bodyMedium)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .glassButton(style: .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Go back")
                .accessibilityHint("Returns to the previous step")
            }

            Spacer()

            // Step indicator text
            Text("Step \(currentStep.stepNumber) of \(ConsentFlowStep.totalSteps)")
                .font(Typography.caption)
                .foregroundColor(.hcdTextSecondary)
                .accessibilityHidden(true)

            Spacer()

            // Forward / Complete
            if currentStep == .digitalSignature {
                HStack(spacing: Spacing.md) {
                    declineButton
                    agreeButton
                }
            } else {
                Button(action: goForward) {
                    HStack(spacing: Spacing.xs) {
                        Text("Continue")
                            .font(Typography.bodyMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .glassButton(isActive: true, style: .primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continue")
                .accessibilityHint("Moves to the next step")
            }
        }
    }

    private var declineButton: some View {
        Button(action: declineConsent) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                Text("Decline")
                    .font(Typography.bodyMedium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassButton(style: .destructive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Decline consent")
        .accessibilityHint("Declines consent and closes the wizard")
    }

    private var agreeButton: some View {
        let canAgree = canCompleteConsent

        return Button(action: completeConsent) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                Text("I Agree")
                    .font(Typography.bodyMedium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassButton(isActive: canAgree, style: .primary)
        }
        .buttonStyle(.plain)
        .disabled(!canAgree)
        .accessibilityLabel("I agree")
        .accessibilityHint(canAgree
            ? "Confirms your consent and starts the session"
            : "Disabled. You must type your name and accept all required permissions first.")
    }

    // MARK: - Shared Components

    private func readAloudButton(text: String) -> some View {
        Button(action: { toggleSpeaking(text: text) }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16))
                Text(isSpeaking ? "Stop Reading" : "Read Aloud")
                    .font(Typography.bodyMedium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassButton(isActive: isSpeaking, style: .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSpeaking ? "Stop reading aloud" : "Read aloud")
        .accessibilityHint(isSpeaking
            ? "Stops the text-to-speech"
            : "Reads the introduction text out loud")
    }

    private func infoCard(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.hcdInfo)
                .accessibilityHidden(true)

            Text(text)
                .font(Typography.body)
                .foregroundColor(.hcdTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .glassCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Computed Properties

    private var canCompleteConsent: Bool {
        let nameEntered = !participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return nameEntered && template.allRequiredAccepted
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    // MARK: - Navigation Actions

    private func goForward() {
        stopSpeaking()
        guard let nextStep = ConsentFlowStep(rawValue: currentStep.rawValue + 1) else { return }
        if reduceMotion {
            currentStep = nextStep
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep = nextStep
            }
        }
    }

    private func goBack() {
        stopSpeaking()
        guard let previousStep = ConsentFlowStep(rawValue: currentStep.rawValue - 1) else { return }
        if reduceMotion {
            currentStep = previousStep
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep = previousStep
            }
        }
    }

    // MARK: - Consent Actions

    private func acceptAllPermissions() {
        for index in template.permissions.indices {
            template.permissions[index].isAccepted = true
        }
    }

    private func completeConsent() {
        stopSpeaking()
        let status: ConsentStatus = .writtenConsent
        let acceptedNames = template.permissions
            .filter { $0.isAccepted }
            .map { $0.title }
            .joined(separator: ", ")
        let notes = "Digital consent by \(participantName). Template: \(template.name) v\(template.version) (\(template.language.displayName)). Accepted: \(acceptedNames)."
        consentTracker.setConsent(status, for: sessionId, notes: notes)
        onComplete(status)
    }

    private func declineConsent() {
        stopSpeaking()
        let status: ConsentStatus = .declined
        let notes = "Participant declined consent. Template: \(template.name) v\(template.version) (\(template.language.displayName))."
        consentTracker.setConsent(status, for: sessionId, notes: notes)
        onComplete(status)
    }

    // MARK: - Language Switching

    private func updateTemplateForLanguage(_ language: ConsentLanguage) {
        switch language {
        case .english:
            template = ConsentTemplate.defaultEnglish()
        case .spanish:
            template = ConsentTemplate.defaultSpanish()
        case .french:
            template = ConsentTemplate.defaultFrench()
        default:
            // For languages without a full translation, use English as a fallback
            template = ConsentTemplate.defaultEnglish()
            template.language = language
        }
    }

    // MARK: - Text-to-Speech

    private func toggleSpeaking(text: String) {
        if isSpeaking {
            stopSpeaking()
        } else {
            startSpeaking(text: text)
        }
    }

    #if os(macOS)
    private func startSpeaking(text: String) {
        let synth = NSSpeechSynthesizer()

        // Select a voice appropriate for the current language
        let voiceIdentifier = voiceForLanguage(template.language)
        if let voiceId = voiceIdentifier {
            synth.setVoice(NSSpeechSynthesizer.VoiceName(rawValue: voiceId))
        }

        speechSynthesizer = synth
        isSpeaking = synth.startSpeaking(text)

        // Monitor for completion in a background-safe way
        if isSpeaking {
            monitorSpeechCompletion()
        }
    }

    private func stopSpeaking() {
        speechSynthesizer?.stopSpeaking()
        speechSynthesizer = nil
        isSpeaking = false
    }

    private func monitorSpeechCompletion() {
        Task { @MainActor in
            // Poll periodically to detect when speech ends
            while isSpeaking, let synth = speechSynthesizer {
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                if !synth.isSpeaking {
                    isSpeaking = false
                    speechSynthesizer = nil
                    break
                }
            }
        }
    }

    /// Returns a suitable system voice identifier for the given language, or nil for default.
    private func voiceForLanguage(_ language: ConsentLanguage) -> String? {
        let languagePrefix: String
        switch language {
        case .english: languagePrefix = "en"
        case .spanish: languagePrefix = "es"
        case .french: languagePrefix = "fr"
        case .german: languagePrefix = "de"
        case .japanese: languagePrefix = "ja"
        case .chinese: languagePrefix = "zh"
        }

        // Find a voice matching the language prefix
        let availableVoices = NSSpeechSynthesizer.availableVoices
        for voice in availableVoices {
            let voiceAttrs = NSSpeechSynthesizer.attributes(forVoice: voice)
            if let localeId = voiceAttrs[.localeIdentifier] as? String,
               localeId.hasPrefix(languagePrefix) {
                return voice.rawValue
            }
        }

        return nil
    }
    #else
    private func startSpeaking(text: String) {
        let synth = AVSpeechSynthesizer()
        speechSynthesizer = synth

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        // Select a voice appropriate for the current language
        let languageCode = languageCodeForLanguage(template.language)
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        }

        synth.speak(utterance)
        isSpeaking = true

        // Monitor for completion
        monitorSpeechCompletion()
    }

    private func stopSpeaking() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
        speechSynthesizer = nil
        isSpeaking = false
    }

    private func monitorSpeechCompletion() {
        Task { @MainActor in
            // Poll periodically to detect when speech ends
            while isSpeaking, let synth = speechSynthesizer {
                try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                if !synth.isSpeaking {
                    isSpeaking = false
                    speechSynthesizer = nil
                    break
                }
            }
        }
    }

    /// Returns a BCP 47 language code for the given consent language.
    private func languageCodeForLanguage(_ language: ConsentLanguage) -> String {
        switch language {
        case .english: return "en-US"
        case .spanish: return "es-ES"
        case .french: return "fr-FR"
        case .german: return "de-DE"
        case .japanese: return "ja-JP"
        case .chinese: return "zh-CN"
        }
    }
    #endif
}

// MARK: - Preview

#if DEBUG
struct ConsentFlowView_Previews: PreviewProvider {
    static var previews: some View {
        ConsentFlowView(
            consentTracker: ConsentTracker(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview_consent.json")),
            sessionId: UUID(),
            onComplete: { status in },
            onDismiss: { }
        )
        #if os(macOS)
        .frame(width: 700, height: 600)
        #endif
    }
}
#endif
