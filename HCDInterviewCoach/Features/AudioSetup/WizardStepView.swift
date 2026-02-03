//
//  WizardStepView.swift
//  HCDInterviewCoach
//
//  Created by agent-e2 on 2026-02-02.
//  EPIC E2: Audio Setup Wizard - Reusable Step Wrapper
//

import SwiftUI

/// Reusable wrapper view for wizard steps
/// Provides consistent layout, styling, and accessibility for all wizard screens
struct WizardStepView<Content: View, FooterContent: View>: View {

    // MARK: - Properties

    let step: AudioSetupStep
    let title: String
    let subtitle: String?
    let iconName: String
    let iconColor: Color
    let content: Content
    let footer: FooterContent

    @EnvironmentObject private var viewModel: AudioSetupViewModel

    // MARK: - Initialization

    init(
        step: AudioSetupStep,
        title: String,
        subtitle: String? = nil,
        iconName: String,
        iconColor: Color = .accentColor,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> FooterContent
    ) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
        self.content = content()
        self.footer = footer()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            stepHeader

            Divider()
                .padding(.horizontal)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .padding(.horizontal)

            // Footer
            stepFooter
        }
        .frame(minWidth: 500, minHeight: 400)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step \(step.rawValue + 1): \(title)")
    }

    // MARK: - Header

    private var stepHeader: some View {
        HStack(spacing: 16) {
            // Step icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                // Step indicator
                Text("Step \(step.rawValue + 1) of \(AudioSetupStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(24)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Footer

    private var stepFooter: some View {
        HStack(spacing: 12) {
            footer
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Convenience Initializer without Footer

extension WizardStepView where FooterContent == EmptyView {
    init(
        step: AudioSetupStep,
        title: String,
        subtitle: String? = nil,
        iconName: String,
        iconColor: Color = .accentColor,
        @ViewBuilder content: () -> Content
    ) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
        self.content = content()
        self.footer = EmptyView()
    }
}

// MARK: - Standard Navigation Buttons

/// Standard "Back" button for wizard navigation
struct WizardBackButton: View {
    @EnvironmentObject private var viewModel: AudioSetupViewModel
    let action: (() -> Void)?

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    var body: some View {
        Button(action: {
            if let customAction = action {
                customAction()
            } else {
                viewModel.previousStep()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
            }
            .frame(minWidth: 80)
        }
        .buttonStyle(.bordered)
        .disabled(!viewModel.canGoBack)
        .keyboardShortcut(.leftArrow, modifiers: .command)
        .accessibilityLabel("Go back to previous step")
        .accessibilityHint("Press Command Left Arrow")
    }
}

/// Standard "Next" button for wizard navigation
struct WizardNextButton: View {
    @EnvironmentObject private var viewModel: AudioSetupViewModel
    let title: String
    let action: (() -> Void)?

    init(title: String = "Continue", action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: {
            if let customAction = action {
                customAction()
            } else {
                viewModel.nextStep()
            }
        }) {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(minWidth: 100)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canProceed)
        .keyboardShortcut(.return, modifiers: [])
        .accessibilityLabel(title)
        .accessibilityHint("Press Return to continue")
    }
}

/// Standard "Skip" button for optional steps
struct WizardSkipButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Skip")
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip this step")
    }
}

// MARK: - Progress Indicator

/// Visual progress indicator for the wizard
struct WizardProgressIndicator: View {
    @EnvironmentObject private var viewModel: AudioSetupViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AudioSetupStep.allCases) { step in
                progressDot(for: step)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Step \(viewModel.currentStepNumber) of \(viewModel.totalSteps)")
    }

    @ViewBuilder
    private func progressDot(for step: AudioSetupStep) -> some View {
        let isCurrent = step == viewModel.currentStep
        let isComplete = step.rawValue < viewModel.currentStep.rawValue

        Circle()
            .fill(dotColor(isCurrent: isCurrent, isComplete: isComplete))
            .frame(width: isCurrent ? 10 : 8, height: isCurrent ? 10 : 8)
            .overlay {
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: viewModel.currentStep)
    }

    private func dotColor(isCurrent: Bool, isComplete: Bool) -> Color {
        if isCurrent {
            return .accentColor
        } else if isComplete {
            return .green
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Status Badge

/// Displays the status of a setup check
struct SetupStatusBadge: View {
    let status: AudioSetupStatus

    var body: some View {
        HStack(spacing: 6) {
            statusIcon
            statusText
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusBackground)
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
        case .checking:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .skipped:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch status {
        case .pending:
            Text("Not checked")
                .font(Typography.caption)
                .foregroundColor(.secondary)
        case .checking:
            Text("Checking...")
                .font(Typography.caption)
                .foregroundColor(.primary)
        case .success:
            Text("Verified")
                .font(Typography.caption)
                .foregroundColor(.green)
        case .failure:
            Text("Failed")
                .font(Typography.caption)
                .foregroundColor(.red)
        case .skipped:
            Text("Skipped")
                .font(Typography.caption)
                .foregroundColor(.orange)
        }
    }

    private var statusBackground: Color {
        switch status {
        case .pending:
            return Color.gray.opacity(0.1)
        case .checking:
            return Color.blue.opacity(0.1)
        case .success:
            return Color.green.opacity(0.1)
        case .failure:
            return Color.red.opacity(0.1)
        case .skipped:
            return Color.orange.opacity(0.1)
        }
    }

    private var accessibilityDescription: String {
        switch status {
        case .pending:
            return "Status: Not yet checked"
        case .checking:
            return "Status: Checking in progress"
        case .success:
            return "Status: Successfully verified"
        case .failure(let message):
            return "Status: Failed. \(message)"
        case .skipped:
            return "Status: Skipped by user"
        }
    }
}

// MARK: - Info Box

/// Styled information box for instructions and tips
struct WizardInfoBox: View {
    enum Style {
        case info
        case warning
        case tip
        case error

        var iconName: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .tip: return "lightbulb.fill"
            case .error: return "xmark.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .tip: return .yellow
            case .error: return .red
            }
        }

        var backgroundColor: Color {
            switch self {
            case .info: return Color.blue.opacity(0.1)
            case .warning: return Color.orange.opacity(0.1)
            case .tip: return Color.yellow.opacity(0.1)
            case .error: return Color.red.opacity(0.1)
            }
        }

        var borderColor: Color {
            switch self {
            case .info: return Color.blue.opacity(0.3)
            case .warning: return Color.orange.opacity(0.3)
            case .tip: return Color.yellow.opacity(0.3)
            case .error: return Color.red.opacity(0.3)
            }
        }
    }

    let style: Style
    let title: String?
    let message: String

    init(style: Style = .info, title: String? = nil, message: String) {
        self.style = style
        self.title = title
        self.message = message
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: style.iconName)
                .font(Typography.heading2)
                .foregroundColor(style.iconColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let title = title {
                    Text(title)
                        .font(Typography.heading3)
                        .foregroundColor(.primary)
                }

                Text(message)
                    .font(Typography.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(style.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(style.borderColor, lineWidth: 1)
        )
        .cornerRadius(CornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style == .warning ? "Warning" : style == .error ? "Error" : style == .tip ? "Tip" : "Information"): \(title ?? "") \(message)")
    }
}

// MARK: - Inline Troubleshooting Tip

/// A subtle inline tip shown beneath status sections to help users who get stuck.
/// Uses secondary text styling and a lightbulb icon to stay non-intrusive.
struct InlineTroubleshootingTip: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(Typography.caption)
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text(message)
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.orange.opacity(0.06))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(message)")
    }
}

// MARK: - Troubleshooting Section

/// An expandable "Having trouble?" section with common fixes for a wizard step.
/// Stays collapsed by default so it does not clutter the screen.
struct TroubleshootingSection: View {

    /// Model for a single troubleshooting tip inside the section.
    struct Tip: Identifiable {
        let id = UUID()
        let text: String
    }

    let tips: [Tip]
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Toggle header
            Button(action: {
                if reduceMotion {
                    isExpanded.toggle()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.orange)

                    Text("Having trouble?")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Having trouble?")
            .accessibilityHint(isExpanded ? "Collapse troubleshooting tips" : "Expand troubleshooting tips")
            .accessibilityAddTraits(.isButton)

            // Expandable tip list
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(Typography.small)
                                .foregroundColor(.secondary)
                                .frame(width: 14, alignment: .center)
                                .accessibilityHidden(true)

                            Text(tip.text)
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, Spacing.xl)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Setup Error View

/// A comprehensive error display component for the audio setup wizard.
/// Shows a structured error with:
/// - A clear title describing **what** went wrong
/// - A reason explaining **why** it happened
/// - Step-by-step instructions for **how** to fix it
/// - A "Try Again" action button
///
/// Uses Typography tokens for consistent text styling.
struct SetupErrorView: View {
    /// The setup error to display.
    let error: HCDError.AudioSetupError
    /// Closure invoked when the user taps "Try Again".
    let onRetry: () -> Void
    /// Optional closure invoked when the user taps a contextual action (e.g., open settings).
    var onAction: (() -> Void)?
    /// Label for the contextual action button.
    var actionLabel: String?
    /// SF Symbol name for the contextual action button.
    var actionIcon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // MARK: What went wrong
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.heading2)
                    .foregroundColor(.red)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(error.errorDescription ?? "An error occurred")
                        .font(Typography.heading3)
                        .foregroundColor(.primary)

                    if let reason = error.failureReason {
                        Text(reason)
                            .font(Typography.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Divider()

            // MARK: How to fix it
            if let recovery = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("How to fix this")
                        .font(Typography.heading3)
                        .foregroundColor(.primary)

                    Text(recovery)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
            }

            // MARK: Action buttons
            HStack(spacing: Spacing.md) {
                Button(action: onRetry) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(Typography.body)
                        Text("Try Again")
                            .font(Typography.bodyMedium)
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Try again")
                .accessibilityHint("Re-runs the check for this step")

                if let onAction = onAction,
                   let actionLabel = actionLabel {
                    Button(action: onAction) {
                        HStack(spacing: Spacing.xs) {
                            if let icon = actionIcon {
                                Image(systemName: icon)
                                    .font(Typography.body)
                            }
                            Text(actionLabel)
                                .font(Typography.bodyMedium)
                        }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(actionLabel)
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.red.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error: \(error.errorDescription ?? "Unknown error")")
    }
}

// MARK: - Video Tutorial Link

/// A subtle link component that points to a video tutorial for a wizard step.
/// Shows a play icon alongside a descriptive label. Tapping opens the URL in the
/// user's default browser. The URLs are placeholders that will be updated once
/// tutorial videos are produced.
struct VideoTutorialLink: View {
    let title: String
    let url: String

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button(action: openTutorial) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "play.circle")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .underline()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Opens video tutorial in your default web browser")
    }

    private func openTutorial() {
        guard let link = URL(string: url) else { return }
        openURL(link)
    }
}

// MARK: - Instruction Step

/// A numbered instruction step for guides
struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String?
    let isComplete: Bool

    init(number: Int, title: String, description: String? = nil, isComplete: Bool = false) {
        self.number = number
        self.title = title
        self.description = description
        self.isComplete = isComplete
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.accentColor)
                    .frame(width: 28, height: 28)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if let description = description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description ?? "")")
        .accessibilityValue(isComplete ? "Completed" : "Not completed")
    }
}
