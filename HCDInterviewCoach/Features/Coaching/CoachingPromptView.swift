//
//  CoachingPromptView.swift
//  HCD Interview Coach
//
//  EPIC E6: Coaching Engine
//  Floating overlay UI for coaching prompts
//

import SwiftUI

// MARK: - Coaching Prompt View

/// Floating overlay view for displaying coaching prompts.
/// Supports graceful fade in/out animations and user dismissal.
struct CoachingPromptView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: CoachingViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Body

    var body: some View {
        if let prompt = viewModel.currentPrompt {
            promptCard(prompt)
                .opacity(viewModel.promptOpacity)
                .scaleEffect(reduceMotion ? 1.0 : viewModel.promptScale)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Coaching prompt")
                .accessibilityHint("Press Escape to dismiss, Return to accept")
                .accessibilityAddTraits(.isModal)
        }
    }

    // MARK: - Prompt Card

    @ViewBuilder
    private func promptCard(_ prompt: CoachingPrompt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            promptHeader(prompt)

            // Prompt text
            promptContent(prompt)

            // Action buttons
            promptActions()

            // Auto-dismiss progress
            autoDismissProgress()

            // Keyboard hints
            if viewModel.showKeyboardHints {
                keyboardHints()
            }
        }
        .padding(16)
        .frame(maxWidth: 360)
        .background(promptBackground())
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hcdCoaching.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Header

    @ViewBuilder
    private func promptHeader(_ prompt: CoachingPrompt) -> some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: prompt.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.hcdCoaching)

            // Type label
            Text(prompt.type.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.hcdTextSecondary)

            Spacer()

            // Prompt count badge
            if viewModel.showPromptCount {
                promptCountBadge()
            }

            // Close button
            Button(action: { viewModel.dismissPrompt() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.hcdTextTertiary)
                    .frame(width: 24, height: 24)
                    .background(Color.hcdBackgroundSecondary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss prompt")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func promptContent(_ prompt: CoachingPrompt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main prompt text
            Text(prompt.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.hcdTextPrimary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            // Reason/context (if provided)
            if !prompt.reason.isEmpty {
                Text(prompt.reason)
                    .font(.system(size: 12))
                    .foregroundColor(.hcdTextSecondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private func promptActions() -> some View {
        HStack(spacing: 8) {
            // Snooze button
            Button(action: { viewModel.snoozePrompt() }) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("Later")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.hcdTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Snooze prompt")
            .accessibilityHint("Press Space")

            Spacer()

            // Accept button
            Button(action: { viewModel.acceptPrompt() }) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Got it")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.hcdCoaching)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Accept prompt")
            .accessibilityHint("Press Return")
        }
    }

    // MARK: - Auto-dismiss Progress

    @ViewBuilder
    private func autoDismissProgress() -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.hcdBorderLight)
                    .frame(height: 2)

                // Progress fill
                Rectangle()
                    .fill(Color.hcdCoaching.opacity(0.5))
                    .frame(width: geometry.size.width * (1 - viewModel.autoDismissProgress), height: 2)
            }
        }
        .frame(height: 2)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    // MARK: - Keyboard Hints

    @ViewBuilder
    private func keyboardHints() -> some View {
        HStack(spacing: 16) {
            keyboardHint(key: "esc", action: "dismiss")
            keyboardHint(key: "return", action: "accept")
            keyboardHint(key: "space", action: "snooze")
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func keyboardHint(key: String, action: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.hcdTextTertiary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.hcdBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(action)
                .font(.system(size: 9))
                .foregroundColor(.hcdTextTertiary)
        }
    }

    // MARK: - Prompt Count Badge

    @ViewBuilder
    private func promptCountBadge() -> some View {
        Text("\(viewModel.promptCount)/\(viewModel.maxPrompts)")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.hcdTextTertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.hcdBackgroundSecondary)
            .clipShape(Capsule())
    }

    // MARK: - Background

    @ViewBuilder
    private func promptBackground() -> some View {
        #if os(macOS)
        VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
        #else
        Color.hcdSurfaceElevated
        #endif
    }
}

// MARK: - Coaching Overlay Container

/// Container view that positions the coaching prompt overlay
struct CoachingOverlayContainer: View {

    @ObservedObject var viewModel: CoachingViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Transparent background (doesn't block clicks)
                Color.clear

                // Positioned prompt
                if viewModel.viewState.isVisible || viewModel.currentPrompt != nil {
                    CoachingPromptView(viewModel: viewModel)
                        .position(
                            x: xPosition(for: viewModel.overlayPosition, in: geometry),
                            y: yPosition(for: viewModel.overlayPosition, in: geometry)
                        )
                }
            }
        }
        .allowsHitTesting(viewModel.currentPrompt != nil)
    }

    private func xPosition(for position: OverlayPosition, in geometry: GeometryProxy) -> CGFloat {
        let promptWidth: CGFloat = 360
        let padding: CGFloat = 20

        switch position {
        case .topLeft, .bottomLeft:
            return padding + promptWidth / 2
        case .topRight, .bottomRight:
            return geometry.size.width - padding - promptWidth / 2
        case .center:
            return geometry.size.width / 2
        }
    }

    private func yPosition(for position: OverlayPosition, in geometry: GeometryProxy) -> CGFloat {
        let promptHeight: CGFloat = 180
        let padding: CGFloat = 20

        switch position {
        case .topLeft, .topRight:
            return padding + promptHeight / 2
        case .bottomLeft, .bottomRight:
            return geometry.size.height - padding - promptHeight / 2
        case .center:
            return geometry.size.height / 2
        }
    }
}

// MARK: - Coaching Toggle Button

/// Toggle button for enabling/disabling coaching during a session
struct CoachingToggleButton: View {

    @ObservedObject var viewModel: CoachingViewModel

    var body: some View {
        Button(action: { viewModel.toggleCoaching() }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isEnabled ? "lightbulb.fill" : "lightbulb.slash")
                    .font(.system(size: 14))

                if viewModel.isEnabled {
                    Text("Coaching On")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(viewModel.isEnabled ? .hcdCoaching : .hcdTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                viewModel.isEnabled
                    ? Color.hcdCoaching.opacity(0.15)
                    : Color.hcdBackgroundSecondary
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isEnabled ? "Disable coaching" : "Enable coaching")
    }
}

// MARK: - Coaching Status Badge

/// Status badge showing coaching state and prompt count
struct CoachingStatusBadge: View {

    @ObservedObject var viewModel: CoachingViewModel

    var body: some View {
        HStack(spacing: 6) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Status text
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.hcdTextSecondary)

            // Prompt count
            if viewModel.isEnabled && viewModel.promptCount > 0 {
                Text("\(viewModel.promptCount)/\(viewModel.maxPrompts)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.hcdTextTertiary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.hcdBackgroundSecondary)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var label = "Coaching status: \(statusText)"
        if viewModel.isEnabled && viewModel.promptCount > 0 {
            label += ", \(viewModel.promptCount) of \(viewModel.maxPrompts) prompts shown"
        }
        return label
    }

    private var statusColor: Color {
        switch viewModel.viewState {
        case .inactive:
            return .hcdTextDisabled
        case .idle:
            return .hcdSuccess
        case .appearing, .visible:
            return .hcdCoaching
        case .disappearing:
            return .hcdCoaching.opacity(0.5)
        case .cooldown:
            return .hcdWarning
        }
    }

    private var statusText: String {
        switch viewModel.viewState {
        case .inactive:
            return "Off"
        case .idle:
            return "Ready"
        case .appearing, .visible:
            return "Active"
        case .disappearing:
            return "Dismissing"
        case .cooldown:
            return "Cooldown"
        }
    }
}

// MARK: - Visual Effect Blur (macOS)

#if os(macOS)
import AppKit

/// NSVisualEffectView wrapper for SwiftUI
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif

// MARK: - Preview Provider

#if DEBUG
struct CoachingPromptView_Previews: PreviewProvider {
    static var previews: some View {
        let service = CoachingService()
        let viewModel = CoachingViewModel(coachingService: service)

        // Simulate a prompt
        let _ = {
            viewModel.enableCoaching()
        }()

        return Group {
            // Overlay container
            CoachingOverlayContainer(viewModel: viewModel)
                .frame(width: 800, height: 600)
                .background(Color.hcdBackground)
                .previewDisplayName("Overlay Container")

            // Toggle button
            CoachingToggleButton(viewModel: viewModel)
                .padding()
                .background(Color.hcdBackground)
                .previewDisplayName("Toggle Button")

            // Status badge
            CoachingStatusBadge(viewModel: viewModel)
                .padding()
                .background(Color.hcdBackground)
                .previewDisplayName("Status Badge")
        }
    }
}
#endif
