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

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header with glass styling
            stepHeader

            // Glass divider
            glassDivider

            // Content area with glass background
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    content
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(contentBackground)

            // Glass divider
            glassDivider

            // Footer with glass styling
            stepFooter
        }
        .frame(minWidth: 500, minHeight: 400)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Step \(step.rawValue + 1): \(title)")
    }

    // MARK: - Glass Divider

    private var glassDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5),
                        Color.white.opacity(colorScheme == .dark ? 0.02 : 0.15),
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Content Background

    private var contentBackground: some View {
        Color.clear
            .background(.ultraThinMaterial.opacity(0.3))
    }

    // MARK: - Header

    private var stepHeader: some View {
        HStack(spacing: Spacing.lg) {
            // Step icon with glass styling
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                iconColor.opacity(0.2),
                                iconColor.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 40
                        )
                    )
                    .frame(width: 64, height: 64)

                // Glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        iconColor.opacity(0.5),
                                        iconColor.opacity(0.2),
                                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: iconColor.opacity(0.25), radius: 8, x: 0, y: 4)

                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Step indicator with glass pill
                Text("Step \(step.rawValue + 1) of \(AudioSetupStep.allCases.count)")
                    .font(Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2), lineWidth: 0.5)
                            )
                    )

                // Title
                Text(title)
                    .font(Typography.heading1)
                    .foregroundColor(.primary)

                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial.opacity(0.5))
    }

    // MARK: - Footer

    private var stepFooter: some View {
        HStack(spacing: Spacing.md) {
            footer
        }
        .padding(Spacing.xl)
        .background(.ultraThinMaterial.opacity(0.5))
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

/// Standard "Back" button for wizard navigation with glass styling
struct WizardBackButton: View {
    @EnvironmentObject private var viewModel: AudioSetupViewModel
    @Environment(\.colorScheme) private var colorScheme
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
            HStack(spacing: Spacing.xs) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Back")
                    .font(Typography.bodyMedium)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .glassButton(isActive: false, style: .secondary)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canGoBack)
        .opacity(viewModel.canGoBack ? 1.0 : 0.5)
        .keyboardShortcut(.leftArrow, modifiers: .command)
        .accessibilityLabel("Go back to previous step")
        .accessibilityHint("Press Command Left Arrow")
    }
}

/// Standard "Next" button for wizard navigation with glass styling
struct WizardNextButton: View {
    @EnvironmentObject private var viewModel: AudioSetupViewModel
    @Environment(\.colorScheme) private var colorScheme
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
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.bodyMedium)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.sm)
            .glassButton(isActive: true, style: .primary)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canProceed)
        .opacity(viewModel.canProceed ? 1.0 : 0.5)
        .keyboardShortcut(.return, modifiers: [])
        .accessibilityLabel(title)
        .accessibilityHint("Press Return to continue")
    }
}

/// Standard "Skip" button for optional steps with glass styling
struct WizardSkipButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text("Skip")
                    .font(Typography.body)
                Image(systemName: "arrow.right.circle")
                    .font(Typography.caption)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip this step")
    }
}

// MARK: - Progress Indicator

/// Visual progress indicator for the wizard with glass styling
struct WizardProgressIndicator: View {
    @EnvironmentObject private var viewModel: AudioSetupViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(AudioSetupStep.allCases) { step in
                progressDot(for: step)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 0.5)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: Step \(viewModel.currentStepNumber) of \(viewModel.totalSteps)")
    }

    @ViewBuilder
    private func progressDot(for step: AudioSetupStep) -> some View {
        let isCurrent = step == viewModel.currentStep
        let isComplete = step.rawValue < viewModel.currentStep.rawValue

        ZStack {
            Circle()
                .fill(dotBackground(isCurrent: isCurrent, isComplete: isComplete))
                .frame(width: isCurrent ? 12 : 10, height: isCurrent ? 12 : 10)
                .overlay(
                    Circle()
                        .stroke(
                            dotBorderColor(isCurrent: isCurrent, isComplete: isComplete),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: dotShadowColor(isCurrent: isCurrent, isComplete: isComplete),
                    radius: isCurrent ? 4 : 2,
                    x: 0,
                    y: 1
                )

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: AnimationTiming.normal), value: viewModel.currentStep)
    }

    private func dotBackground(isCurrent: Bool, isComplete: Bool) -> some ShapeStyle {
        if isCurrent {
            return AnyShapeStyle(Color.accentColor)
        } else if isComplete {
            return AnyShapeStyle(Color.green)
        } else {
            return AnyShapeStyle(Material.ultraThinMaterial)
        }
    }

    private func dotBorderColor(isCurrent: Bool, isComplete: Bool) -> Color {
        if isCurrent {
            return Color.accentColor.opacity(0.5)
        } else if isComplete {
            return Color.green.opacity(0.5)
        } else {
            return Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3)
        }
    }

    private func dotShadowColor(isCurrent: Bool, isComplete: Bool) -> Color {
        if isCurrent {
            return Color.accentColor.opacity(0.3)
        } else if isComplete {
            return Color.green.opacity(0.2)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}

// MARK: - Status Badge

/// Displays the status of a setup check with glass styling
struct SetupStatusBadge: View {
    let status: AudioSetupStatus

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Spacing.sm) {
            statusIcon
            statusText
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(statusGlassBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(statusBorderGradient, lineWidth: 1)
        )
        .shadow(color: statusShadowColor, radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle.dashed")
                .font(Typography.body)
                .foregroundColor(.secondary)
        case .checking:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(Typography.body)
                .foregroundColor(.green)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .font(Typography.body)
                .foregroundColor(.red)
        case .skipped:
            Image(systemName: "minus.circle.fill")
                .font(Typography.body)
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
                .fontWeight(.medium)
                .foregroundColor(.green)
        case .failure:
            Text("Failed")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(.red)
        case .skipped:
            Text("Skipped")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var statusGlassBackground: some View {
        ZStack {
            // Glass material base
            Material.ultraThinMaterial

            // Status color tint
            statusTintColor
        }
    }

    private var statusTintColor: Color {
        switch status {
        case .pending:
            return Color.gray.opacity(0.05)
        case .checking:
            return Color.blue.opacity(0.08)
        case .success:
            return Color.green.opacity(0.1)
        case .failure:
            return Color.red.opacity(0.1)
        case .skipped:
            return Color.orange.opacity(0.08)
        }
    }

    private var statusBorderGradient: LinearGradient {
        let baseColor: Color
        switch status {
        case .pending:
            baseColor = .gray
        case .checking:
            baseColor = .blue
        case .success:
            baseColor = .green
        case .failure:
            baseColor = .red
        case .skipped:
            baseColor = .orange
        }

        return LinearGradient(
            colors: [
                baseColor.opacity(0.4),
                baseColor.opacity(0.15),
                Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusShadowColor: Color {
        switch status {
        case .pending:
            return Color.black.opacity(0.05)
        case .checking:
            return Color.blue.opacity(0.15)
        case .success:
            return Color.green.opacity(0.2)
        case .failure:
            return Color.red.opacity(0.2)
        case .skipped:
            return Color.orange.opacity(0.15)
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

/// Styled information box for instructions and tips with glass styling
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

        var tintOpacity: Double {
            switch self {
            case .info: return 0.08
            case .warning: return 0.1
            case .tip: return 0.08
            case .error: return 0.12
            }
        }
    }

    let style: Style
    let title: String?
    let message: String

    @Environment(\.colorScheme) private var colorScheme

    init(style: Style = .info, title: String? = nil, message: String) {
        self.style = style
        self.title = title
        self.message = message
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Icon with glass circle background
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        style.iconColor.opacity(0.4),
                                        style.iconColor.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: style.iconColor.opacity(0.2), radius: 4, x: 0, y: 2)

                Image(systemName: style.iconName)
                    .font(Typography.heading3)
                    .foregroundColor(style.iconColor)
            }
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
        .background(infoBoxBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            style.iconColor.opacity(0.3),
                            style.iconColor.opacity(0.1),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: style.iconColor.opacity(0.1), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style == .warning ? "Warning" : style == .error ? "Error" : style == .tip ? "Tip" : "Information"): \(title ?? "") \(message)")
    }

    @ViewBuilder
    private var infoBoxBackground: some View {
        ZStack {
            Material.ultraThinMaterial
            style.iconColor.opacity(style.tintOpacity)
        }
    }
}

// MARK: - Inline Troubleshooting Tip

/// A subtle inline tip shown beneath status sections to help users who get stuck.
/// Uses glass styling with secondary text styling and a lightbulb icon.
struct InlineTroubleshootingTip: View {
    let message: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Lightbulb with subtle glow
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 24, height: 24)

                Image(systemName: "lightbulb.fill")
                    .font(Typography.caption)
                    .foregroundColor(.orange)
            }
            .accessibilityHidden(true)

            Text(message)
                .font(Typography.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Material.ultraThinMaterial
                Color.orange.opacity(0.04)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .stroke(
                    Color.orange.opacity(colorScheme == .dark ? 0.15 : 0.2),
                    lineWidth: 0.5
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(message)")
    }
}

// MARK: - Troubleshooting Section

/// An expandable "Having trouble?" section with common fixes for a wizard step.
/// Uses glass styling and stays collapsed by default so it does not clutter the screen.
struct TroubleshootingSection: View {

    /// Model for a single troubleshooting tip inside the section.
    struct Tip: Identifiable {
        let id = UUID()
        let text: String
    }

    let tips: [Tip]
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Toggle header with glass button styling
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
                    // Question icon with glass background
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 0.5)
                            )

                        Image(systemName: "questionmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
                    }

                    Text("Having trouble?")
                        .font(Typography.bodyMedium)
                        .foregroundColor(.primary)

                    Spacer()

                    // Chevron with rotation
                    Image(systemName: "chevron.right")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Having trouble?")
            .accessibilityHint(isExpanded ? "Collapse troubleshooting tips" : "Expand troubleshooting tips")
            .accessibilityAddTraits(.isButton)

            // Expandable tip list with glass cards
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(Typography.small)
                                .foregroundColor(.orange)
                                .frame(width: 16, alignment: .center)
                                .accessibilityHidden(true)

                            Text(tip.text)
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                    }
                }
                .padding(.leading, Spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.lg)
        .background(
            ZStack {
                Material.ultraThinMaterial
                Color.orange.opacity(0.04)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.orange.opacity(0.08),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Setup Error View

/// A comprehensive error display component for the audio setup wizard.
/// Shows a structured error with glass styling:
/// - A clear title describing **what** went wrong
/// - A reason explaining **why** it happened
/// - Step-by-step instructions for **how** to fix it
/// - A "Try Again" action button
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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // MARK: What went wrong
            HStack(alignment: .top, spacing: Spacing.md) {
                // Error icon with glass background
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.5), Color.red.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.red.opacity(0.25), radius: 6, x: 0, y: 2)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(Typography.heading2)
                        .foregroundColor(.red)
                }
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

            // Glass divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.2),
                            Color.red.opacity(0.05),
                            Color.red.opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // MARK: How to fix it
            if let recovery = error.recoverySuggestion {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                        Text("How to fix this")
                            .font(Typography.heading3)
                            .foregroundColor(.primary)
                    }

                    Text(recovery)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.5))
                        )
                }
            }

            // MARK: Action buttons with glass styling
            HStack(spacing: Spacing.md) {
                Button(action: onRetry) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(Typography.body)
                        Text("Try Again")
                            .font(Typography.bodyMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .glassButton(isActive: true, style: .primary)
                }
                .buttonStyle(.plain)
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
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .glassButton(isActive: false, style: .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(actionLabel)
                }
            }
        }
        .padding(Spacing.lg)
        .background(
            ZStack {
                Material.ultraThinMaterial
                Color.red.opacity(0.06)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.4),
                            Color.red.opacity(0.15),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.red.opacity(0.15), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error: \(error.errorDescription ?? "Unknown error")")
    }
}

// MARK: - Video Tutorial Link

/// A subtle link component that points to a video tutorial for a wizard step.
/// Uses glass styling with a play icon alongside a descriptive label.
struct VideoTutorialLink: View {
    let title: String
    let url: String

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false

    var body: some View {
        Button(action: openTutorial) {
            HStack(spacing: Spacing.sm) {
                // Play icon with glass circle
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.accentColor.opacity(isHovered ? 0.4 : 0.2),
                                    lineWidth: 0.5
                                )
                        )

                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(isHovered ? .accentColor : .secondary)
                }
                .accessibilityHidden(true)

                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(isHovered ? .accentColor : .secondary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(isHovered ? 1 : 0.5))
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
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(title)
        .accessibilityHint("Opens video tutorial in your default web browser")
    }

    private func openTutorial() {
        guard let link = URL(string: url) else { return }
        openURL(link)
    }
}

// MARK: - Instruction Step

/// A numbered instruction step for guides with glass styling
struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String?
    let isComplete: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(number: Int, title: String, description: String? = nil, isComplete: Bool = false) {
        self.number = number
        self.title = title
        self.description = description
        self.isComplete = isComplete
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Step number circle with glass styling
            ZStack {
                // Outer glow for complete state
                if isComplete {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                }

                Circle()
                    .fill(isComplete ? Color.green : .ultraThinMaterial)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isComplete
                                        ? [Color.green.opacity(0.6), Color.green.opacity(0.3)]
                                        : [Color.accentColor.opacity(0.5), Color.accentColor.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: isComplete ? Color.green.opacity(0.25) : Color.accentColor.opacity(0.2),
                        radius: 4,
                        x: 0,
                        y: 2
                    )

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .accentColor)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.bodyMedium)
                    .foregroundColor(.primary)
                    .strikethrough(isComplete, color: .secondary)

                if let description = description {
                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            // Completion indicator
            if isComplete {
                Text("Done")
                    .font(Typography.small)
                    .foregroundColor(.green)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.green.opacity(0.2), lineWidth: 0.5)
                            )
                    )
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(.ultraThinMaterial.opacity(isComplete ? 0.3 : 0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                            lineWidth: 0.5
                        )
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description ?? "")")
        .accessibilityValue(isComplete ? "Completed" : "Not completed")
    }
}
